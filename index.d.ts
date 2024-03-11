interface ABI {
  [key: string]: { [key: string]: unknown };
}

declare module 'hychain-wallet' {
  const _default: ABI;
  export default _default;
}