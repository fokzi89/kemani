<script lang="ts">
	import { onMount } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { 
		Star, MessageCircle, User, Calendar, CheckCircle2, 
		ChevronRight, Flag, AlertTriangle, Trash2, X, AlertCircle
	} from 'lucide-svelte';

	let reviews = $state<any[]>([]);
	let loading = $state(true);
	let stats = $state({
		average: 0,
		total: 0,
		distribution: { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 }
	});

	let providerId = $state<string | null>(null);
	let replyingTo = $state<string | null>(null);
	let reportingReview = $state<any | null>(null);
	let replyContent = $state('');
	let reportReason = $state('');
	let submittingReply = $state(false);
	let submittingReport = $state(false);

	const reportReasons = [
		'Inaccurate Clinical Information',
		'Harassment or Abuse',
		'Spam or Irrelevant Content',
		'Breach of Patient Confidentiality',
		'Inappropriate Language',
		'Other'
	];

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

			// Fetch reviews and their replies and reports
			const { data: reviewsData, error } = await supabase
				.from('healthcare_reviews')
				.select('*, profiles:patient_id(full_name, avatar_url), healthcare_review_replies(*), healthcare_review_reports(*)')
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

	async function handleReport() {
		if (!reportingReview || !reportReason) return;
		submittingReport = true;

		try {
			const { error } = await supabase
				.from('healthcare_review_reports')
				.insert({
					review_id: reportingReview.id,
					reporter_id: providerId,
					reason: reportReason
				});

			if (!error) {
				reportingReview = null;
				reportReason = '';
				await fetchReviews();
			} else {
				console.error('Error submitting report:', error);
			}
		} finally {
			submittingReport = false;
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
				<div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm sticky top-24">
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

					<div class="mt-8 p-4 bg-blue-50 rounded-2xl border border-blue-100">
						<div class="flex items-center gap-2 mb-2 text-blue-700">
							<AlertCircle class="h-4 w-4" />
							<p class="text-xs font-bold uppercase tracking-wider">Safety Tip</p>
						</div>
						<p class="text-xs text-blue-600 leading-relaxed">
							Report reviews that contain personal offensive language or inaccurate medical claims to keep our community safe.
						</p>
					</div>
				</div>
			</div>

			<!-- Review List -->
			<div class="lg:col-span-2 space-y-6">
				{#each reviews as review}
					<div class="bg-white p-6 rounded-3xl border border-gray-100 shadow-sm transition-all relative overflow-hidden">
						{#if review.healthcare_review_reports?.length > 0}
							<div class="absolute top-0 right-0 px-3 py-1 bg-red-50 text-red-600 text-[10px] font-bold rounded-bl-xl border-l border-b border-red-100 flex items-center gap-1.5 animate-pulse">
								<AlertTriangle class="h-3 w-3" /> Reported
							</div>
						{/if}

						<div class="flex justify-between items-start mb-4">
							<div class="flex items-center gap-3">
								<div class="h-10 w-10 bg-gray-100 rounded-full flex items-center justify-center overflow-hidden border border-gray-100 text-gray-300">
									{#if review.profiles?.avatar_url}
										<img src={review.profiles.avatar_url} alt="" class="h-full w-full object-cover" />
									{:else}
										<User class="h-5 w-5" />
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
						
						<p class="text-sm text-gray-600 leading-relaxed italic pr-4">
							"{review.comment}"
						</p>

						{#if review.healthcare_review_replies && review.healthcare_review_replies.length > 0}
							<div class="mt-4 ml-4 md:ml-8 p-4 bg-gray-50 rounded-2xl border border-gray-100 relative group/reply">
								<div class="flex items-center justify-between mb-2">
									<div class="flex items-center gap-2 text-gray-700">
										<MessageCircle class="h-3 w-3" />
										<span class="text-[10px] font-bold uppercase tracking-wider">Your Response</span>
									</div>
									<button 
										onclick={() => { replyingTo = review.id; replyContent = review.healthcare_review_replies[0].content; }}
										class="text-[10px] text-primary-600 font-bold opacity-0 group-hover/reply:opacity-100 transition-opacity"
									>
										Edit
									</button>
								</div>
								<p class="text-xs text-gray-700 leading-relaxed">
									{review.healthcare_review_replies[0].content}
								</p>
								<div class="mt-2 text-[9px] text-gray-400 font-medium">
									Replied on {new Date(review.healthcare_review_replies[0].created_at).toLocaleDateString()}
								</div>
							</div>
						{/if}
						
						<!-- Action Bar -->
						<div class="mt-6 pt-4 border-t border-gray-50 flex items-center justify-between">
							<div class="flex items-center gap-4">
								{#if replyingTo !== review.id}
									<button 
										onclick={() => { replyingTo = review.id; replyContent = review.healthcare_review_replies?.[0]?.content || ''; }}
										class="flex items-center gap-1.5 text-xs font-bold text-gray-700 hover:text-gray-900 transition-colors"
									>
										<MessageCircle class="h-4 w-4" />
										{review.healthcare_review_replies?.length ? 'Edit Reply' : 'Reply'}
									</button>
								{/if}
								
								<button 
									onclick={() => reportingReview = review}
									disabled={review.healthcare_review_reports?.length > 0}
									class="flex items-center gap-1.5 text-xs font-bold {review.healthcare_review_reports?.length > 0 ? 'text-gray-400' : 'text-red-500 hover:text-red-600'} transition-colors"
								>
									<Flag class="h-4 w-4" />
									{review.healthcare_review_reports?.length > 0 ? 'Reported' : 'Report'}
								</button>
							</div>

							{#if review.is_verified}
								<div class="flex items-center gap-1 text-emerald-600">
									<CheckCircle2 class="h-3.5 w-3.5" />
									<span class="text-[10px] font-bold uppercase tracking-wider">Verified</span>
								</div>
							{/if}
						</div>

						<!-- Inline Reply Editor -->
						{#if replyingTo === review.id}
							<div class="mt-4 p-4 bg-gray-50 rounded-2xl border border-gray-200 animate-in slide-in-from-top-2 duration-300">
								<textarea
									bind:value={replyContent}
									placeholder="Write your professional response..."
									class="w-full p-4 text-sm bg-white border border-gray-300 rounded-xl focus:ring-2 focus:ring-gray-900 focus:border-transparent outline-none transition-all placeholder:text-gray-400 min-h-[100px]"
								></textarea>
								<div class="flex justify-end gap-3 mt-3">
									<button 
										onclick={() => { replyingTo = null; replyContent = ''; }}
										class="px-4 py-2 text-xs font-bold text-gray-500 hover:text-gray-700"
									>
										Cancel
									</button>
									<button 
										onclick={() => handleReply(review.id)}
										disabled={submittingReply || !replyContent.trim()}
										class="px-6 py-2 text-xs font-bold text-white bg-gray-900 rounded-xl hover:bg-black disabled:opacity-50 transition-all flex items-center gap-2"
									>
										{#if submittingReply}<div class="h-3 w-3 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>{/if}
										{submittingReply ? 'Saving...' : 'Post Response'}
									</button>
								</div>
							</div>
						{/if}
					</div>
				{/each}
			</div>
		</div>
	{/if}

<!-- Report Modal -->
{#if reportingReview}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm animate-in fade-in">
		<div class="bg-white rounded-3xl shadow-2xl w-full max-w-md overflow-hidden animate-in zoom-in-95 duration-200">
			<div class="p-6 border-b flex items-center justify-between">
				<div class="flex items-center gap-2 text-red-600">
					<AlertTriangle class="h-5 w-5" />
					<h3 class="text-lg font-bold">Report Review</h3>
				</div>
				<button onclick={() => reportingReview = null} class="p-2 hover:bg-gray-100 rounded-xl transition-colors">
					<X class="h-5 w-5 text-gray-500" />
				</button>
			</div>
			
			<div class="p-6 space-y-4">
				<div class="p-4 bg-gray-50 rounded-2xl border border-gray-100">
					<p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-1">Reviewing</p>
					<p class="text-xs text-gray-600 italic">"{reportingReview.comment}"</p>
				</div>

				<div>
					<label class="block text-sm font-bold text-gray-700 mb-2">Why are you reporting this?</label>
					<div class="space-y-2">
						{#each reportReasons as reason}
							<button 
								onclick={() => reportReason = reason}
								class="w-full text-left p-3 rounded-xl border-2 transition-all text-xs font-medium {reportReason === reason ? 'border-gray-900 bg-gray-50 text-gray-900' : 'border-gray-100 hover:border-gray-200 text-gray-600'}"
							>
								{reason}
							</button>
						{/each}
					</div>
				</div>
			</div>

			<div class="p-6 bg-gray-50 flex flex-col gap-3">
				<button 
					onclick={handleReport}
					disabled={submittingReport || !reportReason}
					class="w-full py-3 bg-red-600 text-white font-bold rounded-xl hover:bg-red-700 shadow-lg shadow-red-100 disabled:opacity-50 transition-all flex justify-center items-center gap-2"
				>
					{#if submittingReport}<div class="h-4 w-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>{/if}
					{submittingReport ? 'Submitting Report...' : 'Confirm Report'}
				</button>
				<button 
					onclick={() => reportingReview = null}
					class="w-full py-3 text-sm font-bold text-gray-500 hover:text-gray-700"
				>
					Cancel
				</button>
			</div>
		</div>
	</div>
{/if}
</div>

<style>
	:global(.tracking-tight) { letter-spacing: -0.025em; }
</style>
