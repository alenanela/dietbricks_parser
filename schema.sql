-- Shema diagram https://drawsql.app/teams/a-719/diagrams/dietbricks

CREATE TABLE "meal"(
    "id" bigserial NOT NULL,
    "food_id" BIGINT NOT NULL,
    "serving_unit_id" INTEGER NOT NULL,
    "user_id" BIGINT NOT NULL,
    "amount" BIGINT NOT NULL
);
ALTER TABLE
    "meal" ADD PRIMARY KEY("id");
CREATE TABLE "record_source"(
    "id" SERIAL NOT NULL,
    "source" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "record_source" ADD PRIMARY KEY("id");
CREATE TABLE "food_category"(
    "id" SERIAL NOT NULL,
    "name" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "food_category" ADD PRIMARY KEY("id");
CREATE TABLE "user"(
    "diet_kind_id" INTEGER NOT NULL,
    "id" bigserial NOT NULL,
    "username" VARCHAR(255) NOT NULL,
    "email" VARCHAR(255) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "password" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "user" ADD PRIMARY KEY("id");
CREATE TABLE "nutrution_category"(
    "id" SERIAL NOT NULL,
    "name" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "nutrution_category" ADD PRIMARY KEY("id");
CREATE TABLE "food"(
    "diet_kind_id" INTEGER NULL,
    "category_id" INTEGER NULL,
    "id" bigserial NOT NULL,
    "measure_unit_id" INTEGER NOT NULL,
    "source" VARCHAR(255) NOT NULL,
    "source_id" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "food" ADD PRIMARY KEY("id");
CREATE TABLE "diet"(
    "id" SERIAL NOT NULL,
    "name" BIGINT NOT NULL
);
ALTER TABLE
    "diet" ADD PRIMARY KEY("id");
CREATE TABLE "nutrition"(
    "id" bigserial NOT NULL,
    "measure_unit_id" INTEGER NOT NULL,
    "category_id" INTEGER NULL
);
ALTER TABLE
    "nutrition" ADD PRIMARY KEY("id");
CREATE TABLE "nutritional_data"(
    "id" bigserial NOT NULL,
    "food_id" BIGINT NOT NULL,
    "nutrient_id" BIGINT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL
);
ALTER TABLE
    "nutritional_data" ADD PRIMARY KEY("id");
CREATE TABLE "localization"(
    "record_id" BIGINT NOT NULL,
    "id" bigserial NOT NULL,
    "locale" VARCHAR(255) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "description" VARCHAR(255) NULL,
    "record_source_id" INTEGER NOT NULL
);
ALTER TABLE
    "localization" ADD PRIMARY KEY("id");
CREATE TABLE "measure_unit"(
    "id" SERIAL NOT NULL,
    "name" VARCHAR(255) NOT NULL
);
ALTER TABLE
    "measure_unit" ADD PRIMARY KEY("id");
ALTER TABLE
    "measure_unit" ADD CONSTRAINT "measure_unit_name_unique" UNIQUE("name");
CREATE TABLE "food_serving_unit"(
    "id" SERIAL NOT NULL,
    "food_id" BIGINT NOT NULL,
    "mesuare_unit_id" INTEGER NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "volume" BIGINT NOT NULL
);
ALTER TABLE
    "food_serving_unit" ADD PRIMARY KEY("id");
ALTER TABLE
    "nutritional_data" ADD CONSTRAINT "nutritional_data_nutrient_id_foreign" FOREIGN KEY("nutrient_id") REFERENCES "nutrition"("id");
ALTER TABLE
    "nutrition" ADD CONSTRAINT "nutrition_measure_unit_id_foreign" FOREIGN KEY("measure_unit_id") REFERENCES "measure_unit"("id");
ALTER TABLE
    "meal" ADD CONSTRAINT "meal_food_id_foreign" FOREIGN KEY("food_id") REFERENCES "food"("id");
ALTER TABLE
    "food_serving_unit" ADD CONSTRAINT "food_serving_unit_mesuare_unit_id_foreign" FOREIGN KEY("mesuare_unit_id") REFERENCES "measure_unit"("id");
ALTER TABLE
    "localization" ADD CONSTRAINT "localization_record_source_id_foreign" FOREIGN KEY("record_source_id") REFERENCES "record_source"("id");
ALTER TABLE
    "nutrition" ADD CONSTRAINT "nutrition_category_id_foreign" FOREIGN KEY("category_id") REFERENCES "nutrution_category"("id");
ALTER TABLE
    "meal" ADD CONSTRAINT "meal_user_id_foreign" FOREIGN KEY("user_id") REFERENCES "user"("id");
ALTER TABLE
    "user" ADD CONSTRAINT "user_diet_kind_id_foreign" FOREIGN KEY("diet_kind_id") REFERENCES "diet"("id");
ALTER TABLE
    "meal" ADD CONSTRAINT "meal_serving_unit_id_foreign" FOREIGN KEY("serving_unit_id") REFERENCES "food_serving_unit"("id");
ALTER TABLE
    "nutritional_data" ADD CONSTRAINT "nutritional_data_food_id_foreign" FOREIGN KEY("food_id") REFERENCES "food"("id");
ALTER TABLE
    "food" ADD CONSTRAINT "food_measure_unit_id_foreign" FOREIGN KEY("measure_unit_id") REFERENCES "measure_unit"("id");
ALTER TABLE
    "food" ADD CONSTRAINT "food_diet_kind_id_foreign" FOREIGN KEY("diet_kind_id") REFERENCES "diet"("id");
ALTER TABLE
    "food" ADD CONSTRAINT "food_category_id_foreign" FOREIGN KEY("category_id") REFERENCES "food_category"("id");
ALTER TABLE
    "food_serving_unit" ADD CONSTRAINT "food_serving_unit_food_id_foreign" FOREIGN KEY("food_id") REFERENCES "food"("id");
    
INSERT INTO record_source (id, source) VALUES
(1, 'food'),
(2, 'nutrition'),
(3, 'food_category'),
(4, 'nutrition_category');

INSERT INTO measure_unit (id, name) VALUES
(1, 'kJ'),
(2, 'g'),
(3, 'ml'),
(4, 'mg'),
(5, 'ug'),
(6, 'mg/gN'),
(7, '%T');