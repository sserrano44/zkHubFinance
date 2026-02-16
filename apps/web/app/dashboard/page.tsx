import { DashboardClient } from "../../components/dashboard-client";

export default function DashboardPage() {
  return (
    <section className="stack">
      <article className="card">
        <h2>Hub Position</h2>
        <p className="muted">All accounting is concentrated on Base. Spoke actions only credit after settlement.</p>
      </article>
      <DashboardClient />
    </section>
  );
}
