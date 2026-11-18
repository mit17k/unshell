package dev.unshell.automation;

import java.time.Duration;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public final class Scheduler implements AutoCloseable {
    private final ScheduledExecutorService executor = Executors.newScheduledThreadPool(2);

    public record Job(String name, Duration every, Runnable action) {}

    public void schedule(List<Job> jobs) {
        for (Job job : jobs) {
            executor.scheduleAtFixedRate(
                () -> {
                    try {
                        job.action().run();
                    } catch (RuntimeException e) {
                        System.err.printf("Job %s failed: %s%n", job.name(), e.getMessage());
                    }
                },
                0, job.every().toMillis(), TimeUnit.MILLISECONDS);
        }
    }

    @Override
    public void close() throws InterruptedException {
        executor.shutdown();
        executor.awaitTermination(5, TimeUnit.SECONDS);
    }
}
