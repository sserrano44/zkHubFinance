import { SupplyRepayForm } from "../../components/supply-repay-form";

export default function SupplyPage() {
  return (
    <section className="stack">
      <article className="card">
        <h2>Supply From Worldchain</h2>
        <p className="muted">Funds escrow + bridge first, then settlement credits collateral on Base.</p>
      </article>
      <SupplyRepayForm mode="supply" />
    </section>
  );
}
