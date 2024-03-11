interface ABI {
  [key: string]: string;
}

declare module 'hychain-wallet' {
  const _default: ABI[];
  export default _default;
}