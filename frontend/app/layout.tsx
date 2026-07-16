import "./globals.css";
import Providers from "./components/Providers";

export const metadata = {
  title: "Camel Finance",
  description: "Liquidity Automation Layer",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-[#09090B] text-white">
        <Providers>
          {children}
        </Providers>
      </body>
    </html>
  );
}
