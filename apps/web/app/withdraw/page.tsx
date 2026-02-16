import { BorrowWithdrawForm } from "../../components/borrow-withdraw-form";

export default function WithdrawPage() {
  return (
    <section className="stack">
      <article className="card">
        <h2>Withdraw To Worldchain</h2>
        <p className="muted">Withdrawal is lock-first on Base, then spoke fill, then settlement finalization.</p>
      </article>
      <BorrowWithdrawForm mode="withdraw" />
    </section>
  );
}
