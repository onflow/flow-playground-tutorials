'use strict';
import {Observable} from 'rxjs';
import {spawn} from 'child_process';

class Emulator {
	process;
	constructor() {
		this.started = false;
		this.logging = false;
	}

	start(logging) {
		this.logging = logging;
		this.process = spawn('flow', ['emulator', 'start']);

		return new Observable(subscriber => {
			this.process.stdout.on('data', (data: string) => {
				this.logging && subscriber.next(`LOG: ${data}`);
				if (data.includes('Starting HTTP server')) {
					subscriber.next({started: true});
					this.started = true;
				}
			});
			this.process.stderr.on('data', data => {
				subscriber.error(`stderr: ${data}`, this.process.stderr);
			});
			this.process.on('message', message => {
				console.log(message);
			});
		});
	}

	stop() {
		this.process.end();
	}
}

const instance = new Emulator();

export default instance;
