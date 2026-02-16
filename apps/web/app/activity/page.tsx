import { ActivityClient } from "../../components/activity-client";

export default function ActivityPage() {
  return (
    <section className="stack">
      <article className="card">
        <h2>Intent Activity</h2>
        <p className="muted">Canonical lifecycle from the indexer API.</p>
      </article>
      <ActivityClient />
    </section>
  );
}
