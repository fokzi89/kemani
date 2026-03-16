import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { RtcTokenBuilder, RtcRole } from 'npm:agora-token@2.0.5';

const corsHeaders = {
	'Access-Control-Allow-Origin': '*',
	'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
	// Handle CORS preflight
	if (req.method === 'OPTIONS') {
		return new Response(null, { headers: corsHeaders });
	}

	try {
		// Get Agora credentials from environment
		const AGORA_APP_ID = Deno.env.get('AGORA_APP_ID');
		const AGORA_APP_CERTIFICATE = Deno.env.get('AGORA_APP_CERTIFICATE');

		if (!AGORA_APP_ID || !AGORA_APP_CERTIFICATE) {
			throw new Error('Agora credentials not configured');
		}

		// Create Supabase client
		const supabaseClient = createClient(
			Deno.env.get('SUPABASE_URL') ?? '',
			Deno.env.get('SUPABASE_ANON_KEY') ?? '',
			{
				global: {
					headers: { Authorization: req.headers.get('Authorization')! },
				},
			}
		);

		// Get current user
		const {
			data: { user },
			error: authError,
		} = await supabaseClient.auth.getUser();

		if (authError || !user) {
			return new Response(JSON.stringify({ error: 'Unauthorized' }), {
				status: 401,
				headers: { ...corsHeaders, 'Content-Type': 'application/json' },
			});
		}

		// Get request body
		const { consultation_id, channel_name, role = 'publisher' } = await req.json();

		if (!consultation_id || !channel_name) {
			return new Response(
				JSON.stringify({ error: 'Missing consultation_id or channel_name' }),
				{
					status: 400,
					headers: { ...corsHeaders, 'Content-Type': 'application/json' },
				}
			);
		}

		// Verify user has access to this consultation
		const { data: consultation, error: consultError } = await supabaseClient
			.from('consultations')
			.select('id, patient_id, provider_id')
			.eq('id', consultation_id)
			.single();

		if (consultError || !consultation) {
			return new Response(JSON.stringify({ error: 'Consultation not found' }), {
				status: 404,
				headers: { ...corsHeaders, 'Content-Type': 'application/json' },
			});
		}

		// Check if user is patient or provider
		const { data: provider } = await supabaseClient
			.from('healthcare_providers')
			.select('id')
			.eq('user_id', user.id)
			.single();

		const isPatient = consultation.patient_id === user.id;
		const isProvider = provider && consultation.provider_id === provider.id;

		if (!isPatient && !isProvider) {
			return new Response(JSON.stringify({ error: 'Access denied' }), {
				status: 403,
				headers: { ...corsHeaders, 'Content-Type': 'application/json' },
			});
		}

		// Generate Agora token
		const uid = 0; // 0 means auto-assign
		const agoraRole = role === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;
		const expirationTimeInSeconds = 3600; // 1 hour
		const currentTimestamp = Math.floor(Date.now() / 1000);
		const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

		const token = RtcTokenBuilder.buildTokenWithUid(
			AGORA_APP_ID,
			AGORA_APP_CERTIFICATE,
			channel_name,
			uid,
			agoraRole,
			privilegeExpiredTs
		);

		// Update consultation with Agora details
		const tokenField = isPatient ? 'agora_token_patient' : 'agora_token_provider';
		await supabaseClient
			.from('consultations')
			.update({
				agora_channel_name: channel_name,
				[tokenField]: token,
				agora_token_expiry: new Date(privilegeExpiredTs * 1000).toISOString(),
			})
			.eq('id', consultation_id);

		return new Response(
			JSON.stringify({
				token,
				channel: channel_name,
				uid: uid,
				app_id: AGORA_APP_ID,
				expires_at: new Date(privilegeExpiredTs * 1000).toISOString(),
			}),
			{
				headers: { ...corsHeaders, 'Content-Type': 'application/json' },
			}
		);
	} catch (error) {
		console.error('Error generating Agora token:', error);
		return new Response(JSON.stringify({ error: error.message }), {
			status: 500,
			headers: { ...corsHeaders, 'Content-Type': 'application/json' },
		});
	}
});
