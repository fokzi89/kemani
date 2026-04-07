<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { Star, MessageCircle, User, Calendar, CheckCircle2, ChevronRight } from 'lucide-svelte';

	let reviews = $state<any[]>([]);
	let loading = $state(true);
	let stats = $state({
		average: 0,
		total: 0,
		distribution: { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 }
	});

	let providerId = $state<string | null>(null);
	let replyingTo = $state<string | null>(null);
	let replyContent = $state('');
	let submittingReply = $state(false);

	async function fetchReviews() {
		try {
			const { data: { session } } = await supabase.auth.getSession();
			if (!session) return;

			// Get provider ID
			const { data: provider } = await supabase
				.from('healthcare_providers')
				.select('id')
				.eq('user_id', session.user.id)
				.single();

			if (!provider) return;
			providerId = provider.id;

			// Fetch reviews and their replies
			const { data: reviewsData, error } = await supabase
				.from('healthcare_reviews')
				.select('*, profiles:patient_id(full_name, avatar_url), healthcare_review_replies(*)')
				.eq('provider_id', provider.id)
				.order('created_at', { ascending: false });

			if (!error && reviewsData) {
				reviews = reviewsData;
				calculateStats(reviewsData);
			}
		} catch (err) {
			console.error('Error fetching reviews:', err);
		} finally {
			loading = false;
		}
	}

	onMount(() => {
		fetchReviews();
	});

	async function handleReply(reviewId: string) {
		if (!replyContent.trim()) return;
		submittingReply = true;
		
		try {
			const { error } = await supabase
				.from('healthcare_review_replies')
				.upsert({
					review_id: reviewId,
					provider_id: providerId,
					content: replyContent
				});

			if (!error) {
				replyingTo = null;
				replyContent = '';
				await fetchReviews();
			} else {
				console.error('Error submitting reply:', error);
			}
		} finally {
			submittingReply = false;
		}
	}

	function calculateStats(data: any[]) {
		if (data.length === 0) return;
		const sum = data.reduce((acc, r) => acc + r.rating, 0);
		stats.average = Number((sum / data.length).toFixed(1));
		stats.total = data.length;
		
		const dist: any = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
		data.forEach(r => {
			if (dist[r.rating] !== undefined) dist[r.rating]++;
		});
		stats.distribution = dist;
	}
</script>

<div class="p-6 lg:p-8 max-w-7xl mx-auto space-y-8">
	<!-- Header -->
	<div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
		<div>
			<h1 class="text-3xl font-bold text-gray-900 tracking-tight">Patient Reviews</h1>
			<p class="text-gray-500 mt-1">Manage and respond to patient feedback and ratings</p>
		</div>
		
		<div class="bg-white px-4 py-2 rounded-xl border border-gray-100 shadow-sm flex items-center gap-3">
			<div class="flex items-center gap-1 text-amber-500">
				{#each Array(5) as _, i}
					<Star class="h-4 w-4 {i < Math.round(stats.average || 4.8) ? 'fill-current' : 'text-gray-200'}" />
				{/each}
			</div>
			<span class="text-lg font-bold text-gray-900">{stats.average || 4.8}</span>
			<span class="text-xs text-gray-400 font-medium uppercase tracking-wider">Rating</span>
		</div>
	</div>

	{#if loading}
		<div class="flex items-center justify-center py-20">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
		</div>
	{:else if reviews.length === 0}
		<!-- Empty State / Mock Preview -->
		<div class="bg-white rounded-3xl border border-gray-100 shadow-sm overflow-hidden">
			<div class="p-8 md:p-12 text-center max-w-2xl mx-auto">
				<div class="w-20 h-20 bg-amber-50 rounded-full flex items-center justify-center mx-auto mb-6">
					<Star class="h-10 w-10 text-amber-500 fill-amber-500" />
				</div>
				<h2 class="text-2xl font-bold text-gray-900">Your reviews will appear here</h2>
				<p class="text-gray-500 mt-4 leading-relaxed">
					As you consult with patients, they will be given the opportunity to rate their experience. High ratings help you appear higher in the search directory.
				</p>
				
				<div class="mt-10 grid grid-cols-1 md:grid-cols-2 gap-4 text-left">
					<div class="p-4 bg-gray-50 rounded-2xl border border-gray-100">
						<div class="flex items-center gap-2 mb-2 text-primary-600">
							<CheckCircle2 class="h-4 w-4" />
							<span class="text-xs font-bold uppercase tracking-wider">Visibility</span>
						</div>
						<p class="text-sm text-gray-600">Reviews are public and visible to potential patients on the marketplace.</p>
					</div>
					<div class="p-4 bg-gray-50 rounded-2xl border border-gray-100">
						<div class="flex items-center gap-2 mb-2 text-emerald-600">
							<MessageCircle class="h-4 w-4" />
							<span class="text-xs font-bold uppercase tracking-wider">Interaction</span>
						</div>
						<p class="text-sm text-gray-600">You can respond to reviews to provide additional context or thank your patients.</p>
					</div>
				</div>
			</div>
		</div>
	{:else}
		<div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
			<!-- Stats Sidebar -->
			<div class="space-y-6">
				<div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm">
					<h3 class="text-sm font-bold text-gray-900 uppercase tracking-widest mb-6">Rating Summary</h3>
					
					<div class="space-y-4">
						{#each [5, 4, 3, 2, 1] as stars}
							{@const count = (stats.distribution as any)[stars] || 0}
							{@const percent = stats.total > 0 ? (count / stats.total) * 100 : 0}
							<div class="flex items-center gap-4">
								<span class="text-xs font-bold text-gray-600 w-4">{stars}</span>
								<div class="flex-1 h-2 bg-gray-100 rounded-full overflow-hidden">
									<div class="h-full bg-amber-400 rounded-full" style="width: {percent}%"></div>
								</div>
								<span class="text-xs font-medium text-gray-400 w-8">{count}</span>
							</div>
						{/each}
					</div>
				</div>
			</div>

			<!-- Review List -->
			<div class="lg:col-span-2 space-y-4">
				{#each reviews as review}
					<div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm hover:border-primary-100 transition-all group">
						<div class="flex justify-between items-start mb-4">
							<div class="flex items-center gap-3">
								<div class="h-10 w-10 bg-gray-100 rounded-full flex items-center justify-center overflow-hidden">
									{#if review.profiles?.avatar_url}
										<img src={review.profiles.avatar_url} alt="" class="h-full w-full object-cover" />
									{:else}
										<User class="h-5 w-5 text-gray-400" />
									{/if}
								</div>
								<div>
									<h4 class="text-sm font-bold text-gray-900">{review.profiles?.full_name || 'Anonymous Patient'}</h4>
									<div class="flex items-center gap-2 text-[10px] text-gray-400 font-medium">
										<Calendar class="h-3 w-3" />
										{new Date(review.created_at).toLocaleDateString()}
									</div>
								</div>
							</div>
							
							<div class="flex items-center gap-1 text-amber-500">
								{#each Array(5) as _, i}
									<Star class="h-3 w-3 {i < review.rating ? 'fill-current' : 'text-gray-200'}" />
								{/each}
							</div>
						</div>
						
						<p class="text-sm text-gray-600 leading-relaxed italic">
							"{review.comment}"
						</p>

						{#if review.healthcare_review_replies && review.healthcare_review_replies.length > 0}
							<div class="mt-4 ml-8 p-4 bg-primary-50 rounded-2xl border border-primary-100">
								<div class="flex items-center gap-2 mb-2 text-primary-700">
									<MessageCircle class="h-3 w-3" />
									<span class="text-[10px] font-bold uppercase tracking-wider">Your Response</span>
								</div>
								<p class="text-xs text-gray-700 leading-relaxed">
									{review.healthcare_review_replies[0].content}
								</p>
								<div class="mt-2 text-[9px] text-primary-400 font-medium">
									Replied on {new Date(review.healthcare_review_replies[0].created_at).toLocaleDateString()}
								</div>
							</div>
						{/if}
						
						<div class="mt-6 flex flex-col items-end gap-4">
							{#if replyingTo === review.id}
								<div class="w-full space-y-3">
									<textarea
										bind:value={replyContent}
										placeholder="Write your professional response..."
										class="w-full p-4 text-sm bg-gray-50 border border-gray-200 rounded-2xl focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none transition-all placeholder:text-gray-400 min-h-[100px]"
									></textarea>
									<div class="flex justify-end gap-3">
										<button 
											onclick={() => { replyingTo = null; replyContent = ''; }}
											class="px-4 py-2 text-xs font-bold text-gray-500 hover:text-gray-700 transition-colors"
										>
											Cancel
										</button>
										<button 
											onclick={() => handleReply(review.id)}
											disabled={submittingReply || !replyContent.trim()}
											class="px-6 py-2 text-xs font-bold text-white bg-primary-600 rounded-xl hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed shadow-sm shadow-primary-200 transition-all"
										>
											{submittingReply ? 'Sending...' : 'Send Reply'}
										</button>
									</div>
								</div>
							{:else}
								<button 
									onclick={() => { replyingTo = review.id; replyContent = review.healthcare_review_replies?.[0]?.content || ''; }}
									class="text-xs font-bold text-primary-600 flex items-center gap-1 hover:underline {review.healthcare_review_replies?.length ? 'opacity-50 hover:opacity-100' : 'opacity-0 group-hover:opacity-100'} transition-opacity"
								>
									{review.healthcare_review_replies?.length ? 'Edit Response' : 'Reply to review'} <ChevronRight class="h-3 w-3" />
								</button>
							{/if}
						</div>
					</div>
				{/each}
			</div>
		</div>
	{/if}
</div>

<style>
	:global(.tracking-tight) { letter-spacing: -0.025em; }
</style>
