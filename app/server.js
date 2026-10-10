import "dotenv/config";
import express from "express";
import path from "path";
import { fileURLToPath } from "url";
import { nanoid } from "nanoid";
import pool from "./db/db.js";

const app = express();
const PORT = process.env.PORT || 3000;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

app.post("/api/shorten", async (req, res) => {
  try {
    const { url } = req.body;

    if (!url || !/^https?:\/\//i.test(url)) {
      return res.status(400).json({
        error: "Enter a valid HTTP or HTTPS URL",
      });
    }

    const shortCode = nanoid(7);

    await pool.query(
      `INSERT INTO urls (original_url, short_code)
       VALUES ($1, $2)`,
      [url, shortCode]
    );

    res.status(201).json({
      shortUrl: `${process.env.BASE_URL || `http://localhost:${PORT}`}/${shortCode}`,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Could not shorten URL" });
  }
});

app.get("/health", (req, res) => {
  res.status(200).send("ok");
});

app.get("/:code", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT original_url FROM urls WHERE short_code = $1",
      [req.params.code]
    );

    if (result.rows.length === 0) {
      return res.status(404).send("Short URL not found");
    }

    res.redirect(302, result.rows[0].original_url);
  } catch (error) {
    console.error(error);
    res.status(500).send("Server error");
  }
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});