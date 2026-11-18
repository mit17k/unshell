using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Unshell.Notifications;

public enum Severity { Info, Warning, Error }

public sealed record Notification(string Title, Severity Severity, DateTimeOffset At);

public class Notifier
{
    private readonly List<Notification> _history = new();

    public event EventHandler<Notification>? Raised;

    public async Task NotifyAsync(string title, Severity severity = Severity.Info)
    {
        var notification = new Notification(title, severity, DateTimeOffset.UtcNow);
        _history.Add(notification);
        Raised?.Invoke(this, notification);
        await Task.Delay(TimeSpan.FromMilliseconds(10));
    }

    public IEnumerable<Notification> Recent(int count = 5) =>
        _history.OrderByDescending(n => n.At).Take(count);

    public int ErrorCount => _history.Count(n => n.Severity == Severity.Error);
}
