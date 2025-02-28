library(shiny)
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggalluvial)
library(haven)

# Define the Shiny app
ui <- fluidPage(
  titlePanel("Sankey Plot Generator"),
  
  sidebarLayout(
    sidebarPanel(
      textInput("center_id", "Enter Center ID (CTR_CD):", ""),
      actionButton("generate", "Generate Sankey Plot"),
      helpText("Enter the Center ID corresponding to CTR_CD to generate a Sankey plot.")
    ),
    
    mainPanel(
      plotOutput("sankeyPlot"),
      tableOutput("filteredData")  # Optional: View the filtered data
    )
  )
)

server <- function(input, output) {
  # Load the input datasets
  institutions_data <- read_sas("institution.sas7bdat")
  cand_thor_data <- read_sas("cand_thor.sas7bdat")
  tx_hr_data <- read_sas("tx_hr.sas7bdat")
  ptr_hr_data <- read_sas("ptr_hr_20220101_20221231_pub.sas7bdat")
  
  # Reactive expression to create and filter the iluc_data based on Center ID
  filtered_data <- eventReactive(input$generate, {
    req(input$center_id)  # Ensure input is provided
    
    # Filter the institutions data for the given CTR_CD
    filtered_institutions <- institutions_data %>%
      filter(CTR_CD == input$center_id)
    
    # Filter other datasets based on the mapped institution codes
    relevant_cand_thor <- cand_thor_data %>%
      filter(INST_CD %in% filtered_institutions$INST_CD)
    
    relevant_tx_hr <- tx_hr_data %>%
      filter(INST_CD %in% filtered_institutions$INST_CD)
    
    relevant_ptr_hr <- ptr_hr_data %>%
      filter(INST_CD %in% filtered_institutions$INST_CD)
    
    # Example logic to create iluc_data (adjust as necessary)
    iluc_data <- relevant_cand_thor %>%
      inner_join(relevant_tx_hr, by = "DONOR_ID") %>%
      inner_join(relevant_ptr_hr, by = "DONOR_ID") %>%
      select(DONOR_ID, initial_decision, final_decision, recip_outcome)
    
    # Convert to long format
    iluc_data %>%
      pivot_longer(
        cols = c(initial_decision, final_decision, recip_outcome),
        names_to = "stage",
        values_to = "node"
      ) %>%
      arrange(DONOR_ID, stage)
  })
  
  # Generate the Sankey plot
  output$sankeyPlot <- renderPlot({
    req(filtered_data())  # Ensure data is filtered
    
    ggplot(filtered_data(), aes(x = stage, stratum = node, alluvium = DONOR_ID, fill = node)) +
      geom_flow(stat = "alluvium", curve_type = "spline") +
      geom_stratum() +
      theme_minimal() +
      labs(
        title = "Sankey Plot",
        x = "Stage",
        y = "Count"
      )
  })
  
  # Optional: Display the filtered data
  output$filteredData <- renderTable({
    req(filtered_data())
    filtered_data()
  })
}

# Run the application
shinyApp(ui = ui, server = server)

