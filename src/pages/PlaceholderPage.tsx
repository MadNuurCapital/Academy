import { Construction } from 'lucide-react';
import { EmptyState } from '@/components/ui/States';

/**
 * Stands in for screens arriving in later phases.
 *
 * Every route in the specification is registered from Phase 1 so that
 * navigation, role guards and direct-URL refresh can be verified end-to-end
 * before the features themselves exist. A route that 404s cannot be tested.
 */
export function PlaceholderPage({ title, phase }: { title: string; phase: string }) {
  return (
    <div className="space-y-6">
      <h1>{title}</h1>
      <EmptyState
        icon={Construction}
        title="Not built yet"
        description={`This screen arrives in ${phase}. The route, navigation and permissions around it are already in place.`}
      />
    </div>
  );
}
