import "dotenv/config";
import fs from "fs";
import path from "path";
import { pool } from "./index";

async function init() {
    const schema = fs.readFileSync(path.join(__dirname, "schema.sql"), "utf8");
    await pool.query(schema);
    console.log("Database initialized");
    await pool.end();
}

init().catch((error) => {
    console.error("Failed to initialize database:", error);
    process.exit(1);
});