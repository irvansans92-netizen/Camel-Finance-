"use client";

export default function PreviewCard() {
  return (
    <div className="rounded-2xl border border-border-desert bg-card-desert p-6 shadow-sm">
      <h2 className="text-xl font-bold text-dark-accent mb-4">Preview</h2>
      
      <div className="space-y-3 text-sm text-neutral-500">
        <div className="flex justify-between items-center">
          <span className="font-medium">Optimal Swap</span>
          <span className="font-bold text-dark-accent">0</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="font-medium">Estimated LP</span>
          <span className="font-bold text-dark-accent">0</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="font-medium">Vault Shares</span>
          <span className="font-bold text-dark-accent">0</span>
        </div>
        <div className="flex justify-between items-center">
          <span className="font-medium">Price Per Share</span>
          <span className="font-bold text-dark-accent">1.00</span>
        </div>
      </div>
    </div>
  );
}
