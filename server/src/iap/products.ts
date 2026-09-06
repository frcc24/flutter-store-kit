/// What each Play Console product is worth. The number lives here and only
/// here: the request never says how many hints it bought.
export interface HintProduct {
  readonly id: string;
  readonly hints: number;
}

const PRODUCTS: readonly HintProduct[] = [{ id: 'hint_pack_5', hints: 5 }];

export function hintProduct(id: string): HintProduct | undefined {
  return PRODUCTS.find((product) => product.id === id);
}
