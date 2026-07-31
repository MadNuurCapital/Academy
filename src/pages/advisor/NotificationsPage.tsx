import { Link } from 'react-router-dom';
import { Bell } from 'lucide-react';
import { useMarkNotificationRead, useNotifications } from '@/api/practical';
import { Card, CardBody } from '@/components/ui/Card';
import { EmptyState, LoadingState } from '@/components/ui/States';
import { cn } from '@/lib/cn';

/**
 * In-app notifications.
 *
 * Every row is scoped to its recipient by RLS, and rows are only ever created
 * by security-definer functions running alongside the event that caused them —
 * so nobody can place a notification in someone else's feed.
 */
export function NotificationsPage() {
  const { data: notifications, isLoading } = useNotifications();
  const markRead = useMarkNotificationRead();

  if (isLoading) return <LoadingState label="Loading notifications…" />;

  if (!notifications || notifications.length === 0) {
    return (
      <div className="space-y-6">
        <h1>Notifications</h1>
        <EmptyState
          icon={Bell}
          title="Nothing new"
          description="You will be told here when a quiz is available, feedback needs acknowledging, or coaching is scheduled."
        />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1>Notifications</h1>
      <div className="space-y-2">
        {notifications.map((raw) => {
          const item = raw as {
            id: string;
            title: string;
            body: string | null;
            link: string | null;
            read_at: string | null;
            created_at: string;
          };
          const content = (
            <Card className={cn(!item.read_at && 'border-accent/40 bg-accent/5')}>
              <CardBody className="py-3">
                <p className="text-sm font-medium">{item.title}</p>
                {item.body && (
                  <p className="mt-0.5 text-sm text-muted-foreground">{item.body}</p>
                )}
              </CardBody>
            </Card>
          );

          return item.link ? (
            <Link
              key={item.id}
              to={item.link}
              onClick={() => !item.read_at && markRead.mutate(item.id)}
              className="block"
            >
              {content}
            </Link>
          ) : (
            <div key={item.id}>{content}</div>
          );
        })}
      </div>
    </div>
  );
}
