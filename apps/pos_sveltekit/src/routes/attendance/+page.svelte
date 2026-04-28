<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { supabase } from '$lib/supabase';
	import { page } from '$app/stores';
	import { MapPin, Clock, Calendar, AlertCircle, CheckCircle2, RefreshCw, LogOut, Settings, Plus, Trash2 } from 'lucide-svelte';

	let loading = true;
	let error = '';
	let user: any = null;
	let branch: any = null;
	
	let activeShift: any = null;
	let attendanceHistory: any[] = [];
	let availableShifts: any[] = [];
	
	// Shift Clock In Selection
	let selectedShiftId = '';
	
	// Manager View Tabs
	let activeTab = 'history'; // 'history' | 'settings'
	
	// New Shift Form
	let newShiftName = '';
	let newShiftStart = '08:00';
	let newShiftEnd = '16:00';
	let newShiftGrace = 0;
	
	let locationStatus = 'checking'; // 'checking', 'allowed', 'denied', 'error'
	let locationDistance = 0;
	let locationErrorMsg = '';

	let currentTime = new Date();
	let timeInterval: any;
	
	const MAX_DISTANCE_METERS = 50;

	onMount(async () => {
		timeInterval = setInterval(() => {
			currentTime = new Date();
		}, 1000);

		await fetchUserAndData();
	});

	onDestroy(() => {
		if (timeInterval) clearInterval(timeInterval);
	});

	async function fetchUserAndData() {
		try {
			loading = true;
			const { data: sessionData } = await supabase.auth.getSession();
			if (!sessionData.session) {
				error = 'Not authenticated';
				loading = false;
				return;
			}
			
			const { data: userData, error: userError } = await supabase
				.from('users')
				.select('*, branches:branches!users_branch_id_fkey(*)')
				.eq('id', sessionData.session.user.id)
				.single();
				
			if (userError) throw userError;
			user = userData;
			branch = Array.isArray(userData.branches) ? userData.branches[0] : userData.branches;

			await checkLocation();
			await fetchAvailableShifts();
			await fetchAttendance();
			if (user.canManageStaff) {
				await fetchHistory();
			}
		} catch (err: any) {
			error = err.message || 'Failed to load data';
			console.error(err);
		} finally {
			loading = false;
		}
	}

	async function fetchAvailableShifts() {
		try {
			const { data, error: fetchError } = await supabase
				.from('branch_shifts')
				.select('*')
				.eq('branch_id', branch.id)
				.order('start_time');
			if (fetchError) throw fetchError;
			availableShifts = data || [];
			if (availableShifts.length > 0 && !selectedShiftId) {
				selectedShiftId = availableShifts[0].id;
			}
		} catch (err) {
			console.error('Error fetching shifts:', err);
		}
	}

	async function fetchAttendance() {
		try {
			const { data, error: fetchError } = await supabase
				.from('staff_attendance')
				.select('*, branch_shifts(*)')
				.eq('staff_id', user.id)
				.is('clock_out_at', null)
				.order('clock_in_at', { ascending: false })
				.limit(1);

			if (fetchError) throw fetchError;
			activeShift = data && data.length > 0 ? data[0] : null;
		} catch (err) {
			console.error('Error fetching attendance:', err);
		}
	}

	async function fetchHistory() {
		try {
			const { data, error: fetchError } = await supabase
				.from('staff_attendance')
				.select('*, users!inner(full_name, email), branch_shifts(shift_name)')
				.eq('branch_id', branch.id)
				.order('shift_date', { ascending: false })
				.order('clock_in_at', { ascending: false })
				.limit(50);

			if (fetchError) throw fetchError;
			attendanceHistory = data || [];
		} catch (err) {
			console.error('Error fetching history:', err);
		}
	}

	function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number) {
		const R = 6371e3; // metres
		const φ1 = lat1 * Math.PI/180;
		const φ2 = lat2 * Math.PI/180;
		const Δφ = (lat2-lat1) * Math.PI/180;
		const Δλ = (lon2-lon1) * Math.PI/180;

		const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
				  Math.cos(φ1) * Math.cos(φ2) *
				  Math.sin(Δλ/2) * Math.sin(Δλ/2);
		const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

		return R * c; // in metres
	}

	async function checkLocation() {
		if (!branch || !branch.latitude || !branch.longitude) {
			locationStatus = 'error';
			locationErrorMsg = 'Branch location is not configured.';
			return;
		}

		if (!navigator.geolocation) {
			locationStatus = 'error';
			locationErrorMsg = 'Geolocation is not supported by your browser.';
			return;
		}

		locationStatus = 'checking';
		
		navigator.geolocation.getCurrentPosition(
			(position) => {
				const distance = calculateDistance(
					position.coords.latitude, 
					position.coords.longitude, 
					branch.latitude, 
					branch.longitude
				);
				locationDistance = Math.round(distance);
				
				if (distance <= MAX_DISTANCE_METERS) {
					locationStatus = 'allowed';
				} else {
					locationStatus = 'denied';
					locationErrorMsg = `You are ${locationDistance}m away. Must be within ${MAX_DISTANCE_METERS}m of the branch to clock in/out.`;
				}
			},
			(err) => {
				locationStatus = 'error';
				locationErrorMsg = `Location access denied or failed: ${err.message}`;
			},
			{ enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
		);
	}

	async function handleClockIn() {
		if (locationStatus !== 'allowed') return;
		if (availableShifts.length > 0 && !selectedShiftId) {
			error = 'Please select a shift first.';
			return;
		}
		
		try {
			loading = true;
			error = '';
			
			let shiftStatus = 'on_time';
			let shiftIdToInsert = selectedShiftId || null;
			
			if (shiftIdToInsert) {
				const shift = availableShifts.find(s => s.id === shiftIdToInsert);
				if (shift) {
					const now = new Date();
					const [startH, startM] = shift.start_time.split(':').map(Number);
					const [endH, endM] = shift.end_time.split(':').map(Number);
					
					const shiftStart = new Date(now.getFullYear(), now.getMonth(), now.getDate(), startH, startM, 0);
					const shiftEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), endH, endM, 0);
					
					if (shiftEnd < shiftStart) {
						if (now.getHours() < 12) {
							shiftStart.setDate(shiftStart.getDate() - 1);
						} else {
							shiftEnd.setDate(shiftEnd.getDate() + 1);
						}
					}
					
					const graceMs = (shift.grace_period_minutes || 0) * 60000;
					const twoHoursMs = 2 * 60 * 60000;
					
					if (now > new Date(shiftEnd.getTime() + twoHoursMs) || now < new Date(shiftStart.getTime() - twoHoursMs)) {
						shiftStatus = 'out_of_schedule';
					} else if (now > new Date(shiftStart.getTime() + graceMs)) {
						shiftStatus = 'late';
					}
				}
			}

			const { error: insertError } = await supabase
				.from('staff_attendance')
				.insert({
					tenant_id: user.tenant_id,
					branch_id: branch.id,
					staff_id: user.id,
					clock_in_at: new Date().toISOString(),
					shift_date: new Date().toISOString().split('T')[0],
					shift_id: shiftIdToInsert,
					shift_status: shiftStatus
				});

			if (insertError) throw insertError;
			await fetchAttendance();
			if (user.canManageStaff) await fetchHistory();
		} catch (err: any) {
			error = err.message || 'Failed to clock in';
			console.error(err);
		} finally {
			loading = false;
		}
	}

	async function handleClockOut() {
		if (locationStatus !== 'allowed' || !activeShift) return;
		try {
			loading = true;
			const { error: updateError } = await supabase.rpc('clock_out_staff', {
				p_attendance_id: activeShift.id
			});

			if (updateError) throw updateError;
			await fetchAttendance();
			if (user.canManageStaff) await fetchHistory();
		} catch (err: any) {
			error = err.message || 'Failed to clock out';
			console.error(err);
		} finally {
			loading = false;
		}
	}
	
	async function createShift() {
		try {
			if (!newShiftName || !newShiftStart || !newShiftEnd) {
				error = "Please fill in all shift details.";
				return;
			}
			loading = true;
			const { error: insertError } = await supabase
				.from('branch_shifts')
				.insert({
					tenant_id: user.tenant_id,
					branch_id: branch.id,
					shift_name: newShiftName,
					start_time: newShiftStart,
					end_time: newShiftEnd,
					grace_period_minutes: newShiftGrace
				});
				
			if (insertError) throw insertError;
			
			// Reset form
			newShiftName = '';
			newShiftStart = '08:00';
			newShiftEnd = '16:00';
			newShiftGrace = 0;
			
			await fetchAvailableShifts();
		} catch (err: any) {
			error = err.message || 'Failed to create shift';
		} finally {
			loading = false;
		}
	}
	
	async function deleteShift(shiftId: string) {
		if (!confirm('Are you sure you want to delete this shift?')) return;
		try {
			loading = true;
			const { error: deleteError } = await supabase
				.from('branch_shifts')
				.delete()
				.eq('id', shiftId);
				
			if (deleteError) throw deleteError;
			await fetchAvailableShifts();
		} catch (err: any) {
			error = err.message || 'Failed to delete shift';
		} finally {
			loading = false;
		}
	}
	
	function formatDuration(startISO: string, endISO?: string | null) {
		const start = new Date(startISO).getTime();
		const end = endISO ? new Date(endISO).getTime() : currentTime.getTime();
		const diffMs = end - start;
		const hours = Math.floor(diffMs / 3600000);
		const minutes = Math.floor((diffMs % 3600000) / 60000);
		const seconds = Math.floor((diffMs % 60000) / 1000);
		return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
	}
	
	function getStatusBadgeClass(status: string) {
		switch (status) {
			case 'on_time': return 'bg-green-100 text-green-800';
			case 'late': return 'bg-yellow-100 text-yellow-800';
			case 'out_of_schedule': return 'bg-red-100 text-red-800';
			default: return 'bg-gray-100 text-gray-800';
		}
	}
	
	function formatStatus(status: string) {
		switch (status) {
			case 'on_time': return 'On Time';
			case 'late': return 'Late';
			case 'out_of_schedule': return 'Out of Schedule';
			default: return status || 'Unknown';
		}
	}
</script>

<div class="max-w-6xl mx-auto p-4 md:p-6 lg:p-8 space-y-6">
	<!-- Header -->
	<div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">Attendance</h1>
			<p class="text-sm text-gray-500">Manage your work shifts and track time</p>
		</div>
		
		<div class="text-right">
			<p class="text-xl font-bold text-gray-900">{currentTime.toLocaleTimeString()}</p>
			<p class="text-sm text-gray-500">{currentTime.toLocaleDateString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
		</div>
	</div>

	{#if error}
		<div class="bg-red-50 text-red-700 p-4 rounded-lg flex items-start gap-3">
			<AlertCircle class="h-5 w-5 mt-0.5 shrink-0" />
			<p>{error}</p>
		</div>
	{/if}

	{#if loading && !user}
		<div class="flex items-center justify-center p-12">
			<div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
		</div>
	{:else if user}
		<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
			<!-- Clock In/Out Card -->
			<div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden lg:col-span-1 h-fit">
				<div class="p-6 border-b border-gray-100">
					<h2 class="text-lg font-semibold text-gray-900">Shift Status</h2>
				</div>
				
				<div class="p-6 space-y-6 flex flex-col items-center text-center">
					{#if activeShift}
						<div class="h-24 w-24 rounded-full bg-green-100 flex items-center justify-center text-green-600 mb-2">
							<Clock class="h-10 w-10" />
						</div>
						<div>
							<p class="text-sm font-medium text-green-600 bg-green-50 px-3 py-1 rounded-full inline-block">Clocked In</p>
							<p class="text-3xl font-bold text-gray-900 mt-3 font-mono tracking-tight">
								{formatDuration(activeShift.clock_in_at)}
							</p>
							<p class="text-sm text-gray-500 mt-1">
								Started at {new Date(activeShift.clock_in_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
							</p>
							{#if activeShift.branch_shifts}
								<p class="text-xs font-medium text-indigo-600 mt-2 bg-indigo-50 px-2 py-1 rounded inline-block">
									{activeShift.branch_shifts.shift_name} Shift
								</p>
							{/if}
						</div>
					{:else}
						<div class="h-24 w-24 rounded-full bg-gray-100 flex items-center justify-center text-gray-400 mb-2">
							<Clock class="h-10 w-10" />
						</div>
						<div>
							<p class="text-sm font-medium text-gray-600 bg-gray-50 px-3 py-1 rounded-full inline-block">Not Clocked In</p>
							<p class="text-xl font-bold text-gray-400 mt-3">Ready for your shift</p>
						</div>
						
						{#if availableShifts.length > 0}
							<div class="w-full mt-4 text-left">
								<label for="shiftSelect" class="block text-sm font-medium text-gray-700 mb-1">Select Shift</label>
								<select 
									id="shiftSelect" 
									bind:value={selectedShiftId}
									class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
								>
									{#each availableShifts as shift}
										<option value={shift.id}>{shift.shift_name} ({shift.start_time.slice(0,5)} - {shift.end_time.slice(0,5)})</option>
									{/each}
								</select>
							</div>
						{/if}
					{/if}

					<!-- Location Status -->
					<div class="w-full bg-gray-50 rounded-lg p-4 text-sm mt-4 text-left">
						<div class="flex items-center justify-between mb-2">
							<span class="font-medium text-gray-700 flex items-center gap-1.5">
								<MapPin class="h-4 w-4" /> Location Check
							</span>
							<button onclick={checkLocation} class="text-indigo-600 hover:text-indigo-800 p-1" title="Refresh Location" disabled={locationStatus === 'checking'}>
								<RefreshCw class="h-4 w-4 {locationStatus === 'checking' ? 'animate-spin text-gray-400' : ''}" />
							</button>
						</div>
						
						{#if locationStatus === 'checking'}
							<p class="text-gray-500 flex items-center gap-2">
								<span class="animate-pulse h-2 w-2 bg-indigo-400 rounded-full"></span>
								Verifying location...
							</p>
						{:else if locationStatus === 'allowed'}
							<p class="text-green-600 flex items-center gap-2">
								<CheckCircle2 class="h-4 w-4" />
								At branch location ({locationDistance}m)
							</p>
						{:else}
							<p class="text-red-600 text-xs">
								{locationErrorMsg}
							</p>
						{/if}
					</div>

					<!-- Actions -->
					<div class="w-full pt-2">
						{#if activeShift}
							<button 
								onclick={handleClockOut}
								disabled={locationStatus !== 'allowed' || loading}
								class="w-full py-3 px-4 bg-red-600 hover:bg-red-700 disabled:bg-red-300 text-white font-medium rounded-lg shadow-sm transition-colors flex justify-center items-center gap-2"
							>
								{#if loading}<RefreshCw class="h-5 w-5 animate-spin" />{:else}<LogOut class="h-5 w-5" />{/if}
								Clock Out
							</button>
						{:else}
							<button 
								onclick={handleClockIn}
								disabled={locationStatus !== 'allowed' || loading}
								class="w-full py-3 px-4 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-300 text-white font-medium rounded-lg shadow-sm transition-colors flex justify-center items-center gap-2"
							>
								{#if loading}<RefreshCw class="h-5 w-5 animate-spin" />{:else}<Clock class="h-5 w-5" />{/if}
								Clock In
							</button>
						{/if}
					</div>
				</div>
			</div>

			<!-- Manager Area -->
			{#if user.canManageStaff}
				<div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden lg:col-span-2 flex flex-col h-[650px]">
					<!-- Tabs -->
					<div class="flex border-b border-gray-200 bg-gray-50">
						<button 
							class="flex-1 py-4 px-6 text-sm font-medium transition-colors border-b-2 {activeTab === 'history' ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:bg-gray-100'}"
							onclick={() => activeTab = 'history'}
						>
							<div class="flex items-center justify-center gap-2">
								<Calendar class="h-4 w-4" />
								Attendance History
							</div>
						</button>
						<button 
							class="flex-1 py-4 px-6 text-sm font-medium transition-colors border-b-2 {activeTab === 'settings' ? 'border-indigo-600 text-indigo-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:bg-gray-100'}"
							onclick={() => activeTab = 'settings'}
						>
							<div class="flex items-center justify-center gap-2">
								<Settings class="h-4 w-4" />
								Shift Settings
							</div>
						</button>
					</div>
					
					{#if activeTab === 'history'}
						<div class="p-4 border-b border-gray-100 flex justify-end shrink-0 bg-white">
							<button onclick={fetchHistory} class="text-sm text-indigo-600 hover:text-indigo-800 font-medium flex items-center gap-1">
								<RefreshCw class="h-4 w-4" /> Refresh
							</button>
						</div>
						
						<div class="overflow-x-auto flex-1">
							<table class="w-full text-left border-collapse">
								<thead class="bg-white sticky top-0 shadow-sm z-10">
									<tr>
										<th class="py-3 px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider border-b">Staff</th>
										<th class="py-3 px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider border-b">Date / Shift</th>
										<th class="py-3 px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider border-b">Status</th>
										<th class="py-3 px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider border-b">Clock In/Out</th>
										<th class="py-3 px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider border-b text-right">Hours</th>
									</tr>
								</thead>
								<tbody class="divide-y divide-gray-100">
									{#each attendanceHistory as record}
										<tr class="hover:bg-gray-50 transition-colors">
											<td class="py-3 px-4">
												<p class="text-sm font-medium text-gray-900">{record.users?.full_name || 'Unknown'}</p>
												<p class="text-xs text-gray-500">{record.users?.email || ''}</p>
											</td>
											<td class="py-3 px-4">
												<p class="text-sm text-gray-900">{new Date(record.shift_date).toLocaleDateString()}</p>
												{#if record.branch_shifts}
													<p class="text-xs text-gray-500">{record.branch_shifts.shift_name}</p>
												{:else}
													<p class="text-xs text-gray-400">No shift selected</p>
												{/if}
											</td>
											<td class="py-3 px-4">
												<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium {getStatusBadgeClass(record.shift_status)}">
													{formatStatus(record.shift_status)}
												</span>
											</td>
											<td class="py-3 px-4">
												<p class="text-sm text-gray-900">
													<span class="text-gray-500 text-xs">In:</span> {new Date(record.clock_in_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
												</p>
												<p class="text-sm text-gray-900">
													<span class="text-gray-500 text-xs">Out:</span> 
													{#if record.clock_out_at}
														{new Date(record.clock_out_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
													{:else}
														<span class="text-green-600 text-xs font-medium">Active</span>
													{/if}
												</p>
											</td>
											<td class="py-3 px-4 text-sm font-medium text-gray-900 text-right">
												{#if record.total_hours}
													{record.total_hours.toFixed(2)}h
												{:else if record.clock_in_at && !record.clock_out_at}
													<span class="text-gray-400 font-normal">--</span>
												{/if}
											</td>
										</tr>
									{:else}
										<tr>
											<td colspan="5" class="py-8 text-center text-gray-500">
												No attendance records found.
											</td>
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
					{:else}
						<!-- Shift Settings Tab -->
						<div class="flex-1 overflow-y-auto p-6 bg-gray-50">
							<!-- Create New Shift -->
							<div class="bg-white p-5 rounded-lg border border-gray-200 shadow-sm mb-6">
								<h3 class="text-sm font-medium text-gray-900 mb-4 flex items-center gap-2">
									<Plus class="h-4 w-4 text-indigo-600" /> Create New Shift
								</h3>
								<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4 items-end">
									<div class="lg:col-span-2">
										<label class="block text-xs font-medium text-gray-700 mb-1">Shift Name</label>
										<input type="text" bind:value={newShiftName} placeholder="e.g. Morning Shift" class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
									</div>
									<div>
										<label class="block text-xs font-medium text-gray-700 mb-1">Start Time</label>
										<input type="time" bind:value={newShiftStart} class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
									</div>
									<div>
										<label class="block text-xs font-medium text-gray-700 mb-1">End Time</label>
										<input type="time" bind:value={newShiftEnd} class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
									</div>
									<div>
										<label class="block text-xs font-medium text-gray-700 mb-1">Grace Period (mins)</label>
										<input type="number" min="0" bind:value={newShiftGrace} class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" />
									</div>
								</div>
								<div class="mt-4 flex justify-end">
									<button onclick={createShift} disabled={loading} class="px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 shadow-sm disabled:opacity-50">
										Add Shift
									</button>
								</div>
							</div>
							
							<!-- Existing Shifts -->
							<h3 class="text-sm font-medium text-gray-900 mb-3">Configured Shifts for Branch</h3>
							<div class="space-y-3">
								{#each availableShifts as shift}
									<div class="bg-white p-4 rounded-lg border border-gray-200 shadow-sm flex items-center justify-between">
										<div>
											<p class="font-medium text-gray-900">{shift.shift_name}</p>
											<div class="flex items-center gap-4 mt-1 text-sm text-gray-500">
												<span class="flex items-center gap-1"><Clock class="h-3.5 w-3.5" /> {shift.start_time.slice(0,5)} - {shift.end_time.slice(0,5)}</span>
												<span>Grace: {shift.grace_period_minutes || 0} mins</span>
											</div>
										</div>
										<button onclick={() => deleteShift(shift.id)} class="p-2 text-red-500 hover:text-red-700 hover:bg-red-50 rounded-md transition-colors" title="Delete Shift">
											<Trash2 class="h-5 w-5" />
										</button>
									</div>
								{:else}
									<div class="text-center py-8 bg-white rounded-lg border border-gray-200 border-dashed text-gray-500 text-sm">
										No shifts configured for this branch.
									</div>
								{/each}
							</div>
						</div>
					{/if}
				</div>
			{/if}
		</div>
	{/if}
</div>
