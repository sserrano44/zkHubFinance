import { SupplyRepayForm } from "../../components/supply-repay-form";

export default function RepayPage() {
  return (
    <section className="stack">
      <article className="card">
        <h2>Repay From Worldchain</h2>
        <p className="muted">Repay effects are applied on Base only after bridge delivery + settlement proof.</p>
      </article>
      <SupplyRepayForm mode="repay" />
    </section>
  );
}
