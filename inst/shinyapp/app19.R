library(shiny)
library(shinyjs)
library(ShinyImage)

#version 19
#synchronizes shinyimg and img
#faster image rendering
#updated comments

#TODO 
## (1) still needs to make rendering faster
## (2) need to make imagelog null for null images 
## (3) test all combinations
## (4) add options for more functions in EBImage
## (5) fix documentation on github 

# ______________________ start of UI _____________________
ui <- fluidPage( 
  shinyjs::useShinyjs(),

  titlePanel("Shiny Image"),

  tabsetPanel(id = "tabs", 
    tabPanel("Image Editor", value = "tab1",

      sidebarLayout(
        sidebarPanel(
          radioButtons("radio", label = ("Sample or Upload Image"), 
            choices = list("Sample" = 1, "Upload Image" = 2, "Upload Link" = 3, "Upload Shiny Image" = 4), selected = 1),
          conditionalPanel(
            condition = "input.radio == 2",
            fileInput(inputId = 'file1',
              label = 'Upload Image',
              placeholder = 'JPEG, PNG, and TIFF are supported',
              accept = c(
                "image/jpeg",
                "image/x-png",
                "image/tiff",
                ".jpg",
                ".png",
                ".tiff"))
          ),
          conditionalPanel(
            condition = "input.radio == 3",
            textInput(inputId = "url1", 
              label = 'Upload URL', 
              placeholder = 'JPEG, PNG, and TIFF are supported',
              value = '')
          ),
          conditionalPanel(
            condition = "input.radio == 4", 
            fileInput(inputId = 'file2', 
              label = 'Upload .si file', 
              placeholder = "Must be a ShinyImg Object", 
              accept = c(
                "file/si", 
                ".si"))
          ),
          radioButtons("color", label = ("Color Mode"), choices = list("Color" = 1, "Greyscale" = 2), selected = 1),
          sliderInput("bright", "Increase/Decrease Brightness:", min = -10, max = 10, value = 0, step = 0.1),
          sliderInput("contrast", "Increase/Decrease Contrast:", min = -10, max = 10, value = 0, step = 0.1), 
          sliderInput("gamma", "Increase/Decrease Gamma Correction", min = 0, max = 50, value = 1, step = 0.5),
          # sliderInput("rotation", "Rotate Image", min = 0, max = 360, value = 0, step = 1),
          sliderInput("blurring", "Blur Image", min = 0, max = 20, value = 0, step = 1),
          actionButton("button1", "Undo"), 
          actionButton("button2", "Redo"), 
          actionButton("button3", "Reset")
          #textOutput("dimetext"),
          #textOutput("help")
        ),
        mainPanel(
          HTML(
            paste(
              h3('Image Editor', align = "center"),
              plotOutput("plot3",
                click = "plot_click",
                dblclick = "plot_dblclick",
                hover = "plot_hover",
                brush = "plot_brush"),
              '<br/>',
              column(6, downloadButton("download1", label = "Download JPG Image")),
              column(6, actionButton("download4", label = "Download SI Shiny Image Object")),
              '<br/>',
              tags$style(type='text/css', "#download1 { display: block; width:100%; margin-left: auto; margin-right:auto;}"),
              tags$style(type='text/css', "#download4 { display:block; width:100%; margin-left: auto; margin-right:auto;}"),

              '<br/>',

              h4('Preview Crop', align = "center"),
              h6('Click and drag where you would like to crop the photo. To save the cropped version, press keep', align = "center"),
              '<br/>',
              plotOutput("plot2"),
              tags$style(type='text/css', "#keep { display:block; width:10%; margin-left: auto; margin-right:auto;}"),
              '<br/>',
              shinyjs::hidden(
                actionButton("keep", label = "Keep")
              ),
              '<br/>',

              verbatimTextOutput("info")
            )
          )
        )
      )
    ), 
    tabPanel("View Image Log", value = "tab2", 
      sidebarLayout(
        sidebarPanel(
          radioButtons("radio2", label = ("Current Image or Upload .si File"), 
            choices = list("Current Image" = 1, "Upload .si file" = 2), selected = 1
          ), 
          conditionalPanel(
            condition = "input.radio2 == 2",
            fileInput(inputId = 'file3', 
            label = 'Upload .si file', 
            placeholder = "Must be a ShinyImg Object", 
            accept = c(
              "file/si", 
              ".si"))
          )
        ), 
        mainPanel(
        h3("Image Log"), 
        verbatimTextOutput("ImageLog")
        )
      )
    ) # END OF TAB PANEL
  ) # END OF TAB SET PANEL
) # END OF UI
 

# ______________________ start of server _____________________
server <- function(input, output, session) {
  options(shiny.maxRequestSize=30*1024^2) #file can be up to 30 mb; default is 5 mb
  shinyImageFile <- reactiveValues(shiny_img_origin = NULL)

  #moved free standing code from the beginning of the file
  #ensures that user is in the right file 
  #has shiny, EBImage, and shinyjs installed
  guiInit <- function() {
    #validate((need(file.exists("~/ShinyImage/R/imagehistory.R"), "Please input imagehistory.R into the same directory that contains app19.R")))
    #source('~/ShinyImage/R/imagehistory.R')

    if (!require("shiny")) {
      cat("shiny is not installed. Please install it first.")
    }

    if (!require("EBImage")) {
      cat("EBImage is not installed. Please install it first.")
    }

    #needed to hide and show the keep button 
    #if clicked accidentally, it causes errors
    if (!require("shinyjs")) {
      cat("shinyjs is not installed. Please install it first.")
    }
  }

  #TODO -- if other radio buttons are clicked; display nothing
  #currently sample or previous image is displayed

#TO DO
#NEED TO FIX PLOT2 WHEN RADIO BUTTON IS SWITCHED
#REALLY SLOW 

  observe({
    guiInit()

    if(input$radio == 1)
    {
      shinyImageFile$shiny_img_origin <- 
        shinyimg$new('https://iksteam.files.wordpress.com/2010/09/untitled1.jpg')
        output$plot3 <- renderPlot({shinyImageFile$shiny_img_origin$render()})
    }
    if (input$radio == 2)
    {
      reset('file1')
      output$plot3 <- renderPlot({ 
        validate(need(!is.null(input$file1), "Must upload a valid jpg, png, or tiff"))
        if (is.null(input$file1))
          return(NULL)
      })
    }
    if(input$radio == 3)
    {
      reset('url1')
      output$plot3 <- renderPlot({ 
        validate(need(input$url1 != "", "Must type in a valid jpeg, png, or tiff"))
        if (is.null(input$file1))
          return(NULL)
      })
    }
    if(input$radio == 4)
    {
      reset('file2')
      output$plot3 <- renderPlot({ 
        validate(need(!is.null(input$file2), "Must upload a valid .si file"))
        if (is.null(input$file1))
          return(NULL)
      })
    }

  })


#might combine with anove observe
  observe({
    #if user clicks a new radio button, uploads new file, or url
    #the sliders will change
    #and the brush will default 
    input$file1
    input$url1
    input$radio
    # if (!is.null(input$file1) || is.na(input$url1) || input$radio > 1)
    # {
    updateSliderInput(session, "bright", value = 0)
    updateSliderInput(session, "contrast", value = 0)
    updateSliderInput(session, "gamma", value = 1)
    updateSliderInput(session, "rotation", value = 0)
    updateSliderInput(session, "blurring", value = 0)
    updateRadioButtons(session, "color", selected = 1)
    session$resetBrush("plot_brush")
    # }
  })
#//////// CDOE FOR RADIO BUTTONS /////////////
  #when user uploads file
  #the datapath is different from the one needed to properly recognize photo
  #so this function renames the file 
  renameUpload <- function(inFile) {
    if(is.null(inFile))
      return(NULL)

    oldNames = inFile$datapath
    newNames = file.path(dirname(inFile$datapath), inFile$name)
    file.rename(from = oldNames, to = newNames)
    inFile$datapath <- newNames

    return(inFile$datapath)
  }

  #if they enter a new file, their file will become the new imageFile
  observeEvent(input$file1, {
    shinyImageFile$shiny_img_origin <- shinyimg$new(renameUpload(input$file1))
    output$plot3 <- renderPlot({shinyImageFile$shiny_img_origin$render()})
  })

  #if they enter a new url, their url will become the new new imageFile
  observeEvent(input$url1, {
    validate(need(input$url1 != "", "Must type in a valid jpeg, png, or tiff"))
    shinyImageFile$shiny_img_origin <- shinyimg$new(input$url1)
    output$plot3 <- renderPlot({shinyImageFile$shiny_img_origin$render()})
  })

  #if user uploads an image log, they will see the picture with previous settings
  #need to update sliders
  observeEvent(input$file2, {
    shinyImageFile$shiny_img_origin$load(renameUpload(input$file2))
    output$plot3 <- renderPlot({shinyImageFile$shiny_img_origin$render()})

    #need to update sliders to saved image settings
    updateSliderInput(session, "bright", value = shinyImageFile$shiny_img_origin$get_brightness() * 10)
    updateSliderInput(session, "contrast", value = (shinyImageFile$shiny_img_origin$get_contrast() - 1) * 10)
    updateSliderInput(session, "gamma", value = shinyImageFile$shiny_img_origin$get_gamma())
    updateSliderInput(session, "blurring", value = shinyImageFile$shiny_img_origin$get_blur())
    # updateSliderInput(session, "rotation", value = shinyImageFile$shiny_img_origin$get_rotate())
    updateRadioButtons(session, "color", selected = shinyImageFile$shiny_img_origin$get_color() + 1)
  })

#//////// END OF CODE FOR RADIO BUTTONS /////////////

#//////// CODE FOR CROPPING AND PLOTS /////////////

  #prompts shiny to look at recursive crop
  observe({
    recursiveCrop()
  })

  #only executes when keep is clicked 
  recursiveCrop <- eventReactive(input$keep,{
    isolate({
      p <- input$plot_brush 
      shinyImageFile$shiny_img_origin$cropxy(p$xmin,p$xmax,p$ymin,p$ymax)
      output$plot3 <- renderPlot({shinyImageFile$shiny_img_origin$render()})
    })
    session$resetBrush("plot_brush")
  })
  
  #hides the keep button in the instance in which the user highlighted the plot
  #then clicks on the side so that the brush plot disappears
  #if user clicks keep without a valid brush, there will be errors
  #so we need to hide the button
  observeEvent(is.null(input$plot_brush), {
      shinyjs::hide("keep")
  })

  #creates a clone of the image in the main image viewer
  #shows the user a preview of the cropped image 
  #since shinyimg saves every image that is edited, we use a clone
  #so that we aren't saving any of the previews
  #till the user clicks keep
  croppedShiny <- function(image)
  {
    p <- input$plot_brush
    validate(need(p != 'NULL', "Highlight a portion of the photo to see a cropped version!"))
    validate(need(p$xmax <= shinyImageFile$shiny_img_origin$size()[1], "Highlighted portion is out of bounds on the x-axis of your image 1"))
    validate(need(p$ymax <= shinyImageFile$shiny_img_origin$size()[2], "Highlighted portion is out of bounds on the x-axis of your image 1"))
    validate(need(p$xmin >= 0, "Highlighted portion is out of bounds on the x-axis of your image 2"))
    validate(need(p$ymin >= 0, "Highlighted portion is out of bounds on the y-axis of your image 2"))
 
    preview <- shinyImageFile$shiny_img_origin$copy()
    preview$set_autodisplay()
    return(preview$cropxy(p$xmin,p$xmax,p$ymin,p$ymax))
  }

  #shows a preview of the cropped function
  #shows the keep button (originally hiding) 

  #TODO
  #either 1) render image after sliders are updated
  # 2) make the plot disappear if the image changes
  # 3) do nothing
  output$plot2 <- renderPlot({
    p <- input$plot_brush
    validate(need(p != 'NULL', "Highlight a portion of the photo to see a cropped version!"))
    validate(need(p$xmax <= shinyImageFile$shiny_img_origin$size()[1], "Highlighted portion is out of bounds on the x-axis of your image 1"))
    validate(need(p$ymax <= shinyImageFile$shiny_img_origin$size()[2], "Highlighted portion is out of bounds on the x-axis of your image 1"))
    validate(need(p$xmin >= 0, "Highlighted portion is out of bounds on the x-axis of your image 2"))
    validate(need(p$ymin >= 0, "Highlighted portion is out of bounds on the y-axis of your image 2"))

    croppedShiny(shinyImageFile$shiny_img_origin)
    shinyjs::show("keep")
  })

  #UPDATES SLIDERS
  #takes slider input and updates the image
  #if statements are to skip rendering the image in the beginning
  #with the preset image alterations
  observeEvent(input$bright, {
    if (input$bright != 0)
    {
      shinyImageFile$shiny_img_origin$set_brightness(input$bright / 10)
      output$plot3 <- renderPlot(shinyImageFile$shiny_img_origin$render())
      output$plot2 <- renderPlot({
        croppedShiny(shinyImageFile$shiny_img_origin)
        shinyjs::show("keep")
      })
    }
  })

  observeEvent(input$contrast, {
    #shiny img
    if (input$contrast != 0) {
      actualContrast = 1 + (input$contrast / 10)
      shinyImageFile$shiny_img_origin$set_contrast(actualContrast)
      output$plot3 <- renderPlot(shinyImageFile$shiny_img_origin$render())
      output$plot2 <- renderPlot({
        croppedShiny(shinyImageFile$shiny_img_origin)
        shinyjs::show("keep")
      })
    }
  })

  observeEvent(input$gamma, {
    if (input$gamma != 1)
    {
      shinyImageFile$shiny_img_origin$set_gamma(input$gamma)
      output$plot3 <- renderPlot(shinyImageFile$shiny_img_origin$render())
      output$plot2 <- renderPlot({
        croppedShiny(shinyImageFile$shiny_img_origin)
        shinyjs::show("keep")
      })    }
  })

  # observeEvent(input$rotation, {
  #   if (input$rotation != 0)
  #   {
  #     shinyImageFile$shiny_img_origin$set_rotate(input$rotation) 
  #     output$plot3 <- renderPlot(shinyImageFile$shiny_img_origin$render())
  #     output$plot2 <- renderPlot({
  #       croppedShiny(shinyImageFile$shiny_img_origin)
  #       shinyjs::show("keep")
  #     })    }
  # })

  observeEvent(input$blurring, {
    if (input$blurring != 0)
    {
      shinyImageFile$shiny_img_origin$set_blur(input$blurring)
      output$plot3 <- renderPlot(shinyImageFile$shiny_img_origin$render())
      output$plot2 <- renderPlot({
        croppedShiny(shinyImageFile$shiny_img_origin)
        shinyjs::show("keep")
      })    }
  })

  observeEvent(input$color, {
    if (input$color == 2)
    {
      shinyImageFile$shiny_img_origin$set_grayscale(1)
      output$plot3 <- renderPlot(shinyImageFile$shiny_img_origin$render())
      output$plot2 <- renderPlot({
        croppedShiny(shinyImageFile$shiny_img_origin)
        shinyjs::show("keep")
      })    }
    #prevents shiny from rendering color image at start up 
    #checks to see if the user clicked color + they can click undo
    if (input$color == 1 && shinyImageFile$shiny_img_origin$shinyUndo() != 0)
    {
     shinyImageFile$shiny_img_origin$set_grayscale(0)
     output$plot3 <- renderPlot(shinyImageFile$shiny_img_origin$render())
      output$plot2 <- renderPlot({
        croppedShiny(shinyImageFile$shiny_img_origin)
        shinyjs::show("keep")
      })    }
  })

#//////// END OF CODE FOR CROPPING AND PLOTS /////////////

#//////// CODE FOR RESET /////////////

  #if user clicks button3 (reset), then we will make imageFile become the original file 
  #also resets brightness, contrast, and gamma correction
  #and resets plot_brush 
  #because its a radio button, we need if statements
  observeEvent(input$button3, {
    if(input$radio == 1)
    {
      shinyImageFile$shiny_img_origin <- shinyimg$new('https://iksteam.files.wordpress.com/2010/09/untitled1.jpg')  
    }
    if(input$radio == 2)
    {
      shinyImageFile$shiny_img_origin <- shinyimg$new(renameUpload(input$file1))
    }
    if(input$radio == 3)
    {
      shinyImageFile$shiny_img_origin <- shinyimg$new(input$url1)
    }

    updateSliderInput(session, "bright", value = 0)
    updateSliderInput(session, "contrast", value = 0)
    updateSliderInput(session, "gamma", value = 1)
    updateSliderInput(session, "rotation", value = 0)
    updateSliderInput(session, "blurring", value = 0)
    updateRadioButtons(session, "color", selected = 1)
    session$resetBrush("plot_brush")
  })

#//////// END OF CODE FOR RESET /////////////

#//////// CODE FOR UNDO AND REDO /////////////

  #undo button
  observeEvent(input$button1, {
    #needed to create a separate functino to check for the number of actions left
    #because of the auto render

    if (shinyImageFile$shiny_img_origin$shinyUndo() == 0) {
      showModal(modalDialog(
      title = "Important message", 
        "No more actions to undo!"))
    }
    else 
    {
      output$plot3 <- renderPlot({
        #TODO: look into why its render and not undo 
      shinyImageFile$shiny_img_origin$render() 
      updateSliderInput(session, "bright", value = shinyImageFile$shiny_img_origin$get_brightness() * 10)
      updateSliderInput(session, "contrast", value = (shinyImageFile$shiny_img_origin$get_contrast() - 1) * 10)
      updateSliderInput(session, "gamma", value = shinyImageFile$shiny_img_origin$get_gamma())
      updateSliderInput(session, "blurring", value = shinyImageFile$shiny_img_origin$get_blur())
      # updateSliderInput(session, "rotation", value = shinyImageFile$shiny_img_origin$get_rotate())
      updateRadioButtons(session, "color", selected = shinyImageFile$shiny_img_origin$get_color() + 1)
     })
     }
  })

  #redo button 
  observeEvent(input$button2, {
    if (shinyImageFile$shiny_img_origin$shinyRedo() == 0) {
      showModal(modalDialog(
      title = "Important message", 
        "No more actions to redo!"))
    }
    #need to put in else statement otherwise it will try to output a null plot
    #because the output of shinyImageFile$shiny_img_origin$redo() is not an image
    #when there are no more actions to redo
    else 
    {
      output$plot3 <- renderPlot({
      shinyImageFile$shiny_img_origin$redo() 
      updateSliderInput(session, "bright", value = shinyImageFile$shiny_img_origin$get_brightness() * 10)
      updateSliderInput(session, "contrast", value = (shinyImageFile$shiny_img_origin$get_contrast() - 1) * 10)
      updateSliderInput(session, "gamma", value = shinyImageFile$shiny_img_origin$get_gamma())
      updateSliderInput(session, "blurring", value = shinyImageFile$shiny_img_origin$get_blur())
      # updateSliderInput(session, "rotation", value = shinyImageFile$shiny_img_origin$get_rotate())
      updateRadioButtons(session, "color", selected = shinyImageFile$shiny_img_origin$get_color() + 1)
    })
    }
  })


#//////// END OF CODE FOR UNDO AND REDO /////////////

#//////// CODE FOR HELPFUL TEXTS /////////////

  #creates an ID for the image log 
  #imgID <- reactive({
  #  if(input$radio == 1)
  #    id <- paste0("id1-sample")
  #  if(input$radio == 2)
  #    id <- paste0("id2-", input$file1[[1]])
  #  if(input$radio == 3)
  #    id <- paste0("id3-", input$url1)
  #  if(input$radio == 4)
  #    id <- paste("id4-prevSaved")
  #return(id)
  #})

  #textbox for user to see what the image ID is
  output$idReader <- renderText({
    paste0("ID: ", imgID())
  })

  #helpful text to show the user the crop function 
  #output$txt1 <- renderText({
  #    "Click and drag where you would like to crop the photo. To save the cropped version, press keep."
  #})

  #creates the textbox below plot2 about the plot_brush details and etc
  output$info <- renderText({
    xy_str <- function(e) {
      if(is.null(e)) return("NULL\n")
      paste0("x=", round(e$x, 1), " y=", round(e$y, 1), "\n")
    }
    xy_range_str <- function(e) {
      if(is.null(e)) return("NULL\n")
      paste0("xmin=", round(e$xmin, 1), " xmax=", round(e$xmax, 1), 
             " ymin=", round(e$ymin, 1), " ymax=", round(e$ymax, 1))
    }

    paste0(
      "click: ", xy_str(input$plot_click),
      "dblclick: ", xy_str(input$plot_dblclick),
      "hover: ", xy_str(input$plot_hover),
      "brush: ", xy_range_str(input$plot_brush)
    )
  })

#//////// END OF CODE FOR HELPFUL TEXTS /////////////

#//////// CODE FOR DOWNLOAD BUTTONS /////////////

  #_________________DOWNLOAD ____________________
  #TODO: if user uploads a .png file, should return same type of file
  #currently only returns jpeg because all three radio buttons dont have an image type

  #allows user to download plot1 - imageFile
  output$download1 <- downloadHandler('temp.jpeg', function(file) {
    shinyImageFile$shiny_img_origin$savejpg(file)
  })

  observeEvent(input$download4, {
    shinyImageFile$shiny_img_origin$save()
    #creates a pop up window 
    showModal(modalDialog(
      title = "Important message", 
      "Check your current directory for workplace.si for Image History!"))
  })

#//////// END OF CODE FOR DOWNLOAD BUTTONS /////////////

#//////// CODE FOR IMAGE LOG VIEWER /////////////

# TO DO 
#NEED TO FIX SAVE BUTTON TO VIEW DIFFERENT IMAGE'S LOG
#NEED TO LET USER DECIDE BETWEEN SEEING HISTORY VS SEEING PREVIOUSLY EDITED IMAGE
#--------------SECOND PANEL: shows user image log-------------

  #radio2 -- view image log options doesnt have a pre-selected button so we are not rendering
  # a image log till the user specifies 
  # observeEvent(input$radio2, {
  #   #if user clicks the first button - current image's log will pop up
  #   if (input$radio2 == 1)
  #     output$ImageLog <- renderPrint({shinyImageFile$shiny_img_origin$get_imghistory()})
  # })

  #if user clicked view image log of current image --> edited image --> clicked the tab again
  # the radio button is set at current image
  # should re-render the img history 
  observeEvent(input$tabs, {
    if (input$tabs == 'tab2' && input$radio2 == 1)
      output$ImageLog <- renderPrint({shinyImageFile$shiny_img_origin$get_imghistory()})
  })

  #should utilize saveHistory
  #need to figure out how to load saveHistory
  observeEvent(input$file3, {
    shinyImageFile$shiny_img_origin$load(renameUpload(input$file3))
    output$ImageLog <- renderPrint({shinyImageFile$shiny_img_origin$get_imghistory()})
  })

  #TODO: include image log of current image
#//////// END OF CODE FOR IMAGE LOG VIEWER /////////////

} #end of server
shinyApp(ui, server)