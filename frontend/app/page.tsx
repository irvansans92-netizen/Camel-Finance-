import Navbar from "./components/Navbar";
import Hero from "./components/Hero";
import DepositCard from "./components/DepositCard";
import PreviewCard from "./components/PreviewCard";
import VaultCard from "./components/VaultCard";

export default function Home() {
  return (
    <main className="min-h-screen bg-[#FAF6F0] pb-20">
      <Navbar />
      <Hero />
      
      <section className="mx-auto mt-10 max-w-md px-4 space-y-6">
        <DepositCard />
        <PreviewCard />
        <VaultCard />
      </section>
    </main>
  );
}
