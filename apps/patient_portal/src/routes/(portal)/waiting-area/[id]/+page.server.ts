export async function load({ parent }) {
  const { provider } = await parent();
  return {
    provider
  };
}
