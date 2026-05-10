CREATE TABLE IF NOT EXISTS favorite_recipes (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  recipe_suggestion_id TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (recipe_suggestion_id) REFERENCES recipe_suggestions(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS favorite_recipes_user_recipe_unique
ON favorite_recipes(user_id, recipe_suggestion_id);
