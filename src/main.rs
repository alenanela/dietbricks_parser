use tokio_postgres::{NoTls};
use calamine::{open_workbook, Reader, Xlsx};
use regex::Regex;
use tokio::fs;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let (mut client, connection) =
        tokio_postgres::connect("host=localhost dbname=dietbricks user=alena", NoTls).await?;

    tokio::spawn(async move {
        if let Err(e) = connection.await {
            eprintln!("connection error: {}", e);
        }
    });

    let script_path = "schema.sql";
    let sql_script = fs::read_to_string(script_path)
        .await
        .map_err(|e| Box::new(e) as Box<dyn std::error::Error>)?;
    drop_tables_and_run_script(&mut client, &sql_script).await?;

    let path = "foodstandards.xlsx";
    let mut workbook: Xlsx<_> = open_workbook(path).expect("Cannot open file");
    let worksheets = ["solid", "liquid"];

    for &worksheet in &worksheets {
        if let Some(Ok(range)) = workbook.worksheet_range(worksheet) {
            if range.rows().count() > 0 {
                let mut is_first_row = true;

                for row in range.rows() {
                    if is_first_row {
                        is_first_row = false;

                        for (col_index, cell) in row.iter().enumerate() {
                            if col_index >= 3 {
                                if let Some(cell_str) = cell.get_string() {
                                    let mut measure_unit_id: i32 = 0;

                                    if let Some(measure_unit_name) = extract_measure_unit(cell_str){ 
                                        let query = "
                                            SELECT id FROM measure_unit WHERE name = $1
                                            LIMIT 1;
                                        ";

                                        let row = client.query_one(query, &[&measure_unit_name]).await?;
                                        measure_unit_id = row.get(0);

                                    } else {
                                        println!("No measure unit!");
                                    }
                                    
                                    if let Some(nutrient_name) = extract_nutrient_name(cell_str) {
                                        // Insert into nutrition and get the id
                                        let row = client.query_one(
                                            "INSERT INTO nutrition (measure_unit_id) VALUES ($1) RETURNING id",
                                            &[&measure_unit_id],
                                        ).await?;
                                        let nutrient_id: i64 = row.get(0);

                                        // Insert into localization
                                        client.execute(
                                            "INSERT INTO localization (record_id, locale, name, record_source_id) VALUES ($1, 'en', $2, 2)",
                                            &[&nutrient_id, &nutrient_name],
                                        ).await?;
                                    } else {
                                        println!("No nutrient name!");
                                    }
                                }
                            }
                        }
                    } else {
                        //Process food data
                        let mut original_id = "";
                        let mut nutrient_id : i64 = 1;
                        let mut food_id : i64 = 0;

                        for (col_index, cell) in row.iter().enumerate() {
                            if let Some(cell_str) = cell.get_string() {
                                if col_index == 0 { //original id
                                    original_id = cell_str;
                                }
                                if col_index == 2 { //name
                                    let mut measure_unit_id: i32 = 2; // gr
                                    let liquids = ["Beer", "Alcoholic", "Cider", "Wine", "Beverage", "Coffee", "drink", 
                                        "Kombucha", "Tea", "Water", "Honey", "syrup", "Honey", "Jam", 
                                        "Soup", "milk", "cream", "Oil", "Honey", "Yoghurt"];

                                    let cell_str_lower = cell_str.to_lowercase();
                                    if liquids.iter().any(|&word| cell_str_lower.contains(word)) ||
                                        worksheet == "liquid" {
                                        measure_unit_id = 3; //ml
                                    }

                                    let data_source = "foodstandards.gov.au";
                                    // Insert into food and get the id
                                    let row = client.query_one(
                                        "INSERT INTO food (source, source_id, measure_unit_id) VALUES ($1, $2, $3) RETURNING id",
                                        &[&data_source, &original_id, &measure_unit_id],
                                    ).await?;
                                    food_id = row.get(0);

                                    // Insert into localization
                                    client.execute(
                                        "INSERT INTO localization (record_id, locale, name, record_source_id) VALUES ($1, 'en', $2, 1)",
                                        &[&food_id, &cell_str],
                                    ).await?;
                                    println!("Inserted: food id: {} {}", food_id, cell_str);

                                }
                                
                            } else {
                                if col_index > 2 { //nutrients data
                                    if let Some(cell_float) = cell.get_float() {
                                        // Insert into nutritional data table and get the id
                                        client.query_one(
                                            "INSERT INTO nutritional_data (food_id, nutrient_id, amount) VALUES ($1, $2, $3) RETURNING id",
                                            &[&food_id, &nutrient_id, &cell_float],
                                        ).await?;

                                        nutrient_id += 1;
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                println!("The range is empty.");
            }
        }
    }
    Ok(())
}

fn extract_nutrient_name(cell_content: &str) -> Option<&str> {
    let re = Regex::new(r"^(.*?)\s*\(").unwrap();
    re.captures(cell_content)
        .and_then(|caps| caps.get(1))
        .map(|m| m.as_str().trim())
}

fn extract_measure_unit(cell_content: &str) -> Option<&str> {
    let re = Regex::new(r"\(([^)]+)\)\s*$").unwrap();
    re.captures(cell_content)
        .and_then(|caps| caps.get(1))
        .map(|m| m.as_str().trim())
}

async fn drop_tables_and_run_script(client: &mut tokio_postgres::Client, sql_script: &str) -> Result<(), tokio_postgres::Error> {
    let transaction = client.transaction().await?;
    let tables = transaction.query("SELECT tablename FROM pg_tables WHERE schemaname = 'public'", &[]).await?;

    for row in tables {
        let table_name: &str = row.get(0);
        let query = format!("DROP TABLE IF EXISTS \"{}\" CASCADE", table_name);
        transaction.execute(&query, &[]).await?;
    }

    transaction.commit().await?;
    client.batch_execute(sql_script).await?;
    Ok(())
}
