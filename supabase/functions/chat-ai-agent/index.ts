import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import OpenAI from "https://esm.sh/openai@4.20.1";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const openaiApiKey = Deno.env.get("OPENAI_API_KEY")!;

const supabase = createClient(supabaseUrl, supabaseKey);
const openai = new OpenAI({ apiKey: openaiApiKey });

// --- Types ---
interface ChatMessage {
    id: string;
    session_id: string;
    sender_type: "customer" | "agent" | "ai";
    message_type: "text" | "image" | "voice" | "pdf" | "product_card";
    content: string;
}

// --- Configuration ---
const AI_RESPONSE_DELAY = 1000; // Simulated latency for UX
const HANDOVER_PHRASES = ["talk to human", "speak to agent", "real person", "human agent", "support person"];

// --- Logic ---
serve(async (req) => {
    // 1. Parse Request (Expecting database webhook payload or direct call)
    const payload = await req.json();

    // If invoked via Database Webhook (INSERT trigger)
    // Payload structure: { type: 'INSERT', table: 'chat_messages', record: { ... }, schema: 'public' }
    const message = payload.record as ChatMessage;

    // 2. Initial Validation
    // Only respond to 'customer' messages
    if (!message || message.sender_type !== "customer") {
        return new Response("Ignored: Not a customer message", { status: 200 });
    }

    try {
        // 3. Check Session Status & Agent Type
        const { data: session, error: sessionError } = await supabase
            .from("chat_sessions")
            .select("status, agent_type, tenant_id, branch_id") // Add tenant_id/branch_id for context
            .eq("id", message.session_id)
            .single();

        if (sessionError || !session) {
            console.error("Session fetch error:", sessionError);
            return new Response("Session not found", { status: 404 });
        }

        // Only respond if AI is the active agent type
        if (session.agent_type !== "ai") {
            return new Response("Ignored: Agent type is not AI", { status: 200 });
        }

        if (session.status !== "active") {
            return new Response("Ignored: Session not active", { status: 200 });
        }

        // 4. Check for Handover Intent (Simple keyword match for MVP, can use LLM classifier)
        const lowerContent = message.content.toLowerCase();
        const isHandover = HANDOVER_PHRASES.some((phrase) => lowerContent.includes(phrase));

        if (isHandover) {
            // Switch Agent Type to 'live'
            await supabase
                .from("chat_sessions")
                .update({ agent_type: "live" })
                .eq("id", message.session_id);

            // Notify Customer
            await sendAIMessage(message.session_id, "I'm transferring you to a human agent. Please hold.");
            // In a real system, this might trigger a notification to support staff
            return new Response("Handover initiated", { status: 200 });
        }

        // 5. Generate AI Response
        // Send Typing Indicator (Optional: using Realtime directly if needed, or just insert row)
        // The client handles "AI" sender typing automatically if we insert quickly?
        // Let's just generate.

        let aiResponseContent = "";

        // Construct Prompt Context
        // TODO: Fetch store context (products, FAQs) based on `session.tenant_id`
        // For MVP, using a generic system prompt.
        const systemPrompt = `
      You are a helpful AI support assistant for an online store.
      Your goal is to assist customers with product questions, order status, and general inquiries.
      If you cannot answer a question, suggest talking to a human agent.
      Be concise, friendly, and professional.
      
      Store Context:
      - Tenant ID: ${session.tenant_id}
      - Branch ID: ${session.branch_id}
    `;

        if (message.message_type === "text") {
            const completion = await openai.chat.completions.create({
                messages: [
                    { role: "system", content: systemPrompt },
                    { role: "user", content: message.content },
                ],
                model: "gpt-4-turbo", // or gpt-3.5-turbo
            });
            aiResponseContent = completion.choices[0].message.content || "I'm sorry, I couldn't generate a response.";

        } else if (message.message_type === "image") {
            // Vision Capability (T040)
            const completion = await openai.chat.completions.create({
                messages: [
                    { role: "system", content: systemPrompt },
                    {
                        role: "user",
                        content: [
                            { type: "text", text: "What is in this image? Is it a product?" },
                            {
                                type: "image_url",
                                image_url: {
                                    url: message.content, // Assuming content is public URL
                                },
                            },
                        ],
                    },
                ],
                model: "gpt-4-vision-preview",
                max_tokens: 300,
            });
            aiResponseContent = completion.choices[0].message.content || "I see an image but I'm not sure what it is.";
        } else {
            aiResponseContent = "I received your file. A human agent can review it shortly.";
        }

        // 6. Send Response
        // Artificial Delay for natural feel
        // await new Promise(resolve => setTimeout(resolve, AI_RESPONSE_DELAY));

        await sendAIMessage(message.session_id, aiResponseContent);

        return new Response("AI Response Sent", { status: 200 });

    } catch (error) {
        console.error("AI Agent Error:", error);
        return new Response(`Error: ${error.message}`, { status: 500 });
    }
});

async function sendAIMessage(sessionId: string, content: string) {
    const { error } = await supabase
        .from("chat_messages")
        .insert({
            session_id: sessionId,
            sender_type: "ai",
            sender_name: "AI Assistant",
            message_type: "text",
            content: content,
        }); // Schema will auto-set created_at

    if (error) throw error;
}
