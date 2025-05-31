const main = require('./scripts/deploy');

main().then(() => {
    console.log("Deployment script executed successfully.");
}).catch((error) => {
    console.error("Error executing deployment script:", error);
    process.exit(1);
});