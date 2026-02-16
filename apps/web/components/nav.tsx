import Link from "next/link";

const routes = [
  ["/dashboard", "Dashboard"],
  ["/supply", "Supply"],
  ["/borrow", "Borrow"],
  ["/repay", "Repay"],
  ["/withdraw", "Withdraw"],
  ["/activity", "Activity"]
] as const;

export function Nav() {
  return (
    <nav className="nav-grid">
      {routes.map(([href, label]) => (
        <Link key={href} href={href} className="nav-link">
          {label}
        </Link>
      ))}
    </nav>
  );
}
