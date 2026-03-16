import AgoraRTC, {
	type IAgoraRTCClient,
	type IAgoraRTCRemoteUser,
	type ICameraVideoTrack,
	type IMicrophoneAudioTrack
} from 'agora-rtc-sdk-ng';

export interface AgoraConfig {
	appId: string;
	channel: string;
	token: string;
	uid: string | number;
}

export class AgoraService {
	private client: IAgoraRTCClient | null = null;
	private localAudioTrack: IMicrophoneAudioTrack | null = null;
	private localVideoTrack: ICameraVideoTrack | null = null;

	private onUserJoinedCallback: ((user: IAgoraRTCRemoteUser) => void) | null = null;
	private onUserLeftCallback: ((user: IAgoraRTCRemoteUser) => void) | null = null;

	constructor() {
		// Create Agora client
		this.client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });
	}

	async join(config: AgoraConfig) {
		if (!this.client) throw new Error('Agora client not initialized');

		// Join the channel
		await this.client.join(config.appId, config.channel, config.token, config.uid);

		// Set up event listeners
		this.client.on('user-published', async (user, mediaType) => {
			await this.client!.subscribe(user, mediaType);

			if (mediaType === 'video') {
				// Remote user published video track
				this.onUserJoinedCallback?.(user);
			}

			if (mediaType === 'audio') {
				// Remote user published audio track
				const remoteAudioTrack = user.audioTrack;
				remoteAudioTrack?.play();
			}
		});

		this.client.on('user-unpublished', (user, mediaType) => {
			if (mediaType === 'video') {
				// Remove remote video
			}
		});

		this.client.on('user-left', (user) => {
			this.onUserLeftCallback?.(user);
		});

		// Create and publish local tracks
		await this.createLocalTracks();
		await this.publishLocalTracks();
	}

	async createLocalTracks() {
		// Create local audio and video tracks
		this.localAudioTrack = await AgoraRTC.createMicrophoneAudioTrack();
		this.localVideoTrack = await AgoraRTC.createCameraVideoTrack();
	}

	async publishLocalTracks() {
		if (!this.client) throw new Error('Client not initialized');
		if (!this.localAudioTrack || !this.localVideoTrack) {
			throw new Error('Local tracks not created');
		}

		await this.client.publish([this.localAudioTrack, this.localVideoTrack]);
	}

	async leave() {
		// Stop and close local tracks
		this.localAudioTrack?.stop();
		this.localAudioTrack?.close();
		this.localVideoTrack?.stop();
		this.localVideoTrack?.close();

		this.localAudioTrack = null;
		this.localVideoTrack = null;

		// Leave the channel
		await this.client?.leave();
	}

	playLocalVideo(elementId: string) {
		if (!this.localVideoTrack) throw new Error('Local video track not created');
		this.localVideoTrack.play(elementId);
	}

	async toggleMicrophone() {
		if (!this.localAudioTrack) return false;
		await this.localAudioTrack.setEnabled(!this.localAudioTrack.enabled);
		return this.localAudioTrack.enabled;
	}

	async toggleCamera() {
		if (!this.localVideoTrack) return false;
		await this.localVideoTrack.setEnabled(!this.localVideoTrack.enabled);
		return this.localVideoTrack.enabled;
	}

	onUserJoined(callback: (user: IAgoraRTCRemoteUser) => void) {
		this.onUserJoinedCallback = callback;
	}

	onUserLeft(callback: (user: IAgoraRTCRemoteUser) => void) {
		this.onUserLeftCallback = callback;
	}

	getRemoteUsers(): IAgoraRTCRemoteUser[] {
		return this.client?.remoteUsers || [];
	}
}
