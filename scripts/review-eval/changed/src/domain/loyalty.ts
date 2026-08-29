export interface LoyaltyTier {
  readonly name: string;
  readonly multiplier: number;
}

export class LoyaltyCalculator {
  private readonly tiers: LoyaltyTier[] = [
    { name: 'standard', multiplier: 1 },
    { name: 'gold', multiplier: 2 },
  ];

  points(totalCents: number, tierName: string): number {
    const tier = this.tiers.find((t) => t.name === tierName);
    return Math.floor((totalCents / 100) * (tier?.multiplier ?? 1));
  }
}
