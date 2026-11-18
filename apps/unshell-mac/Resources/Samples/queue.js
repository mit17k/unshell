// A tiny job queue with bounded concurrency.
export class JobQueue {
  #running = 0;
  #pending = [];

  constructor(limit = 4) {
    this.limit = limit;
  }

  push(task) {
    return new Promise((resolve, reject) => {
      this.#pending.push({ task, resolve, reject });
      this.#drain();
    });
  }

  #drain() {
    while (this.#running < this.limit && this.#pending.length > 0) {
      const { task, resolve, reject } = this.#pending.shift();
      this.#running++;
      Promise.resolve()
        .then(task)
        .then(resolve, reject)
        .finally(() => {
          this.#running--;
          this.#drain();
        });
    }
  }
}

const queue = new JobQueue(2);
await Promise.all([1, 2, 3].map((n) => queue.push(async () => n * 2)));
console.log(`done: ${queue.limit} workers`);
