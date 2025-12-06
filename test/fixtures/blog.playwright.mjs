export async function run({ visit, sleep, clickLink }) {
  await visit("https://nandovieira.com");
  await sleep(1000);
  await clickLink({ text: "Using PostgreSQL and jsonb with Ruby on Rails" });
  await sleep(5000);
}
