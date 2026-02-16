import { BorrowWithdrawForm } from "../../components/borrow-withdraw-form";

export default function BorrowPage() {
  return (
    <section className="stack">
      <article className="card">
        <h2>Borrow To Worldchain</h2>
        <p className="muted">Lifecycle: pending lock -> locked -> filled -> awaiting settlement -> settled.</p>
      </article>
      <BorrowWithdrawForm mode="borrow" />
    </section>
  );
}
