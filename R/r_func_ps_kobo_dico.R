#' @name kobo_dico
#' @rdname kobo_dico
#' @title  Data dictionnary
#'
#' @description  Produce a data dictionnary based on the xlsform for the project
#'
#' @param form The full filename of the form to be accessed (xls or xlsx file).
#' It is assumed that the form is stored in the data folder.
#'
#'
#' @return A "data.table" with the full data dictionnary. To be used in the rest of the analysis.
#'
#' @author Edouard Legoupil
#' @author modified by - Punya Prasad Sapkota
#'
#' @examples
#' kobo_dico()
#'
#' @examples
#' \dontrun{
#' kobo_dico("myform.xls")
#' }
#'
#' @export kobo_dico
#'

kobo_dico <- function(form_file_name) {
  #cat("\n Your form should be placed within the `data` folder. \n \n")
  # read the survey tab of ODK from
  form_tmp <- form_file_name
  ###############################################################################################
  ### First review all questions first
  survey <- read_excel(form_tmp, sheet = "survey")

  ## Rename the variable label
  #names(survey)[names(survey)=="label::English"] <- "label"
  survey<- rename(survey,"label"="label::English")
  #remove '/' from the label
  #survey[["label"]]<-gsub("/","_",survey[["label"]])
  
  ### Get question levels in order to match the variable name
  survey$qlevel <- ""
  ### We can now extract the id of the list name to reconstruct the full label fo rthe question
  cat(" \n Now extracting list name from questions type.\n \n")
  
  #check for 'begin group' and 'end group' -> change to "begin_group" and "end_group"
  survey$type<-ifelse(survey$type=="begin group" | survey$type=="end group",gsub(" ","_",survey$type),survey$type)
  
  #*split type column - Punya
  survey<-separate(survey,type,into = c("qtype","listname"),sep=" ", remove=FALSE,extra="drop", fill="right")
  survey$qtype<-str_trim(survey$qtype)
  survey$listname<-str_trim(survey$listname)
  
  #identify group level begin/end group
  begin_flag<-0
  end_flag<-0
  for (i in 1:nrow(survey)){
      if (survey[i,c("qtype")]=="begin_group") {begin_flag<-begin_flag +1}
      
      #if((survey[i,c("qtype")]!="end_group")) {
        survey$qlevel[i]<-begin_flag - end_flag
      #}
      
      if (survey[i,c("qtype")]=="end_group") {end_flag<-end_flag +1}
      
      #for label
      if (is.na(survey[i,c("label")])) {survey[i,c("label")]<-survey[i,c("name")]}
     
    }
  
  #manage full header name
  kobo_header_group_list<-list()
  kobo_header_group_label_list<-list()
  survey$gname<-""
  survey$gname_label<-""
    for (i in 1:nrow(survey)){
      #get group header level  
      gr_level<-as.numeric(survey[i,c("qlevel")])
      #print(gr_level)
      #pass beging group name to a basket in order of group level
      if (survey[i,c("qtype")] == "begin_group"){
        kobo_header_group_list[gr_level]<-survey[i,c("name")]
        kobo_header_group_label_list[gr_level]<-survey[i,c("label")]
        #
        survey$gname[i]<-kobo_header_group_list[gr_level]
        survey$gname_label[i]<-kobo_header_group_label_list[gr_level]
      }
      #print(kobo_header_group_list)
      # if not begin_group or end_group
      if ((survey[i,c("qtype")] != "begin_group") && (survey[i,c("qtype")] != "end_group") && (gr_level>0)){
        #make group header
        kobo_header<-str_c(kobo_header_group_list[1:gr_level],sep = "/",collapse = "/")
        survey$gname[i]<- str_c(kobo_header,survey[i,c("name")],sep="/")
        # with label
        kobo_header_label<-str_c(kobo_header_group_label_list[1:gr_level],sep = "/",collapse = "/")
        survey$gname_label[i]<- str_c(kobo_header_label,survey[i,c("label")],sep="/")
      }
      
      ###when question is not included in any group
      if ((survey[i,c("qtype")] != "begin_group") && (survey[i,c("qtype")] != "end_group") && (gr_level==0)){
        #make group header
        #kobo_header<-survey[i,c("name")]
        survey$gname[i]<- survey[i,c("name")]
        # with label
        #kobo_header_label<-str_c(kobo_header_group_label_list[1:gr_level],sep = "/",collapse = "/")
        survey$gname_label[i]<- survey[i,c("label")]
        #print(survey$name[i])
      }
      
  } 
  
  #---------------Check COL NAMES In SURVEY---------------------------------
  cat("Checking now for additional information within your xlsform. Note that you can insert them in the xls and re-run the function! \n \n ")
  
  if("recodevar" %in% colnames(survey))
  {
    cat("0- Good: You have a column `recodevar` in your survey worksheet.\n");
  } else
  {cat("0- No column `recodevar` in your survey worksheet. Creating a dummy one for the moment...\n");
    survey$recodevar <- "YES"}
  
  
  if("aggmethod" %in% colnames(survey))
  {
    cat("1- Good: You have a column `aggmethod` in your survey worksheet.\n");
  } else
  {cat("1- No column `aggmethod` in your survey worksheet. Creating a dummy one for the moment...\n");
    survey$aggmethod <- ""}
  
  if("qrankscore" %in% colnames(survey))
  {
    cat("2- Good: You have a column `qrankscore` in your survey worksheet.\n");
  } else
  {cat("2- No column `qrankscore` in your survey worksheet. Creating a dummy one for the moment...\n");
    survey$qrankscore <- ""}
  
  if("qrankgroup" %in% colnames(survey))
  {
    cat("3- Good: You have a column `qrankgroup` in your survey worksheet.\n");
  } else
  {cat("3- No column `qrankgroup` in your survey worksheet. Creating a dummy one for the moment...\n");
    survey$qrankgroup <- ""}
  
  if("sector" %in% colnames(survey))
  {
    cat("4- Good: You have a column `sector` in your survey worksheet.\n");
  } else
  {cat("4- No column `sector` in your survey worksheet. Creating a dummy one for the moment...\n");
    survey$sector <- ""}
  
  if("group" %in% colnames(survey))
  {
    cat("5- Good: You have a column `group` in your survey worksheet.\n");
  } else
  {cat("5- No column `group` in your survey worksheet. Creating a dummy one for the moment...\n");
    survey$group <- ""}
  
  
  #----------------------------------------------------------------------------------------------
  # if("disaggregation" %in% colnames(survey))
  # {
  #   cat("1- Good: You have a column `disaggregation` in your survey worksheet.\n");
  # } else
  # {cat("1- No column `disaggregation` in your survey worksheet. Creating a dummy one for the moment...\n");
  #   survey$disaggregation <- ""}
  # 
  # 
  # if("correlate" %in% colnames(survey))
  # {
  #   cat("2- Good: You have a column `correlate` in your survey worksheet. This will be used to define the variables that should be checked for correlation between each others.\n");
  # } else
  # {cat("2- No column `correlate` in your survey worksheet. Creating a dummy one for the moment...\n");
  #   survey$correlate <- ""}
  
  # if("chapter" %in% colnames(survey))
  # {
  #   cat("3- Good: You have a column `chapter` in your survey worksheet. This will be used to breakdown the generated report\n");
  # } else
  # {cat("3- No column `chapter` in your survey worksheet. Creating a dummy one for the moment ...\n");
  #   survey$chapter <- ""}
  # 
  # if("sensitive" %in% colnames(survey))
  # {
  #   cat("2- Good: You have a column `sensitive` in your survey worksheet. This will be used to distingusih potentially sensitive questions\n");
  # } else
  # {cat("2- No column `sensitive` in your survey worksheet. Creating a dummy one for the moment filled as `non-sensitive`. Other option is to record as `sensitive`...\n");
  #   survey$sensitive <- "non-sensitive"}
  
  
  # if("anonymise" %in% colnames(survey))
  # {
  #   cat("2- Good: You have a column `anonymise` in your survey worksheet. This will be used to anonymise the dataset.\n");
  # } else
  # {cat("2- No column `anonymise` in your survey worksheet. Creating a dummy one for the moment filled as `non-anonymised`. Other options to record are `Remove`, `Reference`, `Mask`, `Generalise` (see readme file) ...\n");
  #   survey$anonymise <- "non-anonymised"}
  
  
  # if("repeatsummarize" %in% colnames(survey))
  # {
  #   cat("4- Good: You have a column `repeatsummarize` in your survey worksheet.\n");
  # } else
  # {cat("4- No column `repeatsummarize` in your survey worksheet. Creating a dummy one for the moment...\n");
  #   survey$repeatsummarize <- ""}
  # 
  # if("variable" %in% colnames(survey))
  # {
  #   cat("5- Good: You have a column `variable` in your survey worksheet.\n");
  # } else
  # {cat("5- No column `variable` in your survey worksheet. Creating a dummy one for the moment...\n");
  #   survey$variable <- ""}
  
  #qraqnkgroup
  #survey$qrankgroup<-ifelse(survey$aggmethod=="RANK3"|survey$aggmethod=="RANK4",str_sub(survey$gname,1,str_length(survey$gname)-2),survey$qrankgroup)
  
  
  ## Pick only selected columns without names
  survey <- survey[ ,c("type",   "name" ,  "label", "qtype","listname","qlevel","recodevar","aggmethod","qrankscore","qrankgroup","sector","group", "gname", "gname_label"
                       #"repeatsummarize","variable","disaggregation",  "chapter", "sensitive","anonymise","correlate"
                       # "indicator","indicatorgroup","indicatortype",
                       # "indicatorlevel","dataexternal","indicatorcalculation","indicatornormalisation"
                       #"indicator","select", "Comment", "indicatordirect", "indicatorgroup" ## This indicator reference
                       # "label::English",
                       #"label::Arabic" ,"hint::Arabic",
                       # "hint::English", "relevant",  "required", "constraint",   "constraint_message::Arabic",
                       # "constraint_message::English", "default",  "appearance", "calculation",  "read_only"  ,
                       # "repeat_count"
  )]
  
  ##--------------------------prepare save name--------------
  
  wb<-openxlsx::createWorkbook()
  addWorksheet(wb,"survey")
  addWorksheet(wb, "choices")
  writeData(wb,sheet="survey",x=as.data.frame(survey))
  
  #write.xlsx2(as.data.frame(survey),gsub(".xlsx","_agg_method.xlsx",form_file_name),sheetName = "survey", row.names=FALSE, na = "")
  
  #survey <- as.data.frame(survey[!is.na(survey$type), ])
  choices <- read_excel(form_tmp, sheet = "choices", col_types = "text")
  ## Rename the variable label
  #names(survey)[names(survey)=="label::English"] <- "label"
  
  ###--Check 'list name' or list_name
  if("list name" %in% colnames(choices))
  {
    choices <- rename(choices,"list_name"="list name")
  } 
  
  #-----------
  choices<- rename(choices,"listnamechoice"="list_name","namechoice"="name","labelchoice"="label::English")
  choices$listnamechoice<-str_trim(choices$listnamechoice)
  
  #choices[["labelchoice"]]<-gsub("/","_",choices[["labelchoice"]])
  
  choices_survey<-full_join(survey,choices,by=c("listname"="listnamechoice"))
  
  #ADDITIONAL CLEAN UP AND PREPARATION
  #create full group/name for select multiple
  choices_survey$gname_full<-""
  choices_survey$gname_full<-ifelse(choices_survey$qtype=="select_multiple",paste0(choices_survey$gname,"/",choices_survey$namechoice),choices_survey$gname)
  #for label
  #
  choices_survey$labelchoice_clean<-choices_survey$labelchoice
  #choices_survey$labelchoice_clean<-str_replace_all(choices_survey$labelchoice_clean,c('\\.'='_','\\*'='','\\:'='','\\?'='','/'='_'))
  choices_survey$labelchoice_clean<-str_replace_all(choices_survey$labelchoice_clean,c('/'='_'))
  #
  choices_survey$gname_full_mlabel<-""
  choices_survey$gname_full_mlabel<-ifelse(choices_survey$qtype=="select_multiple",paste0(choices_survey$gname,"/",choices_survey$labelchoice_clean),choices_survey$gname)
  #
  ##header names with group label
  choices_survey$gname_full_label<-""
  choices_survey$gname_full_label<-ifelse(choices_survey$qtype=="select_multiple",paste0(choices_survey$gname_label,"/",choices_survey$labelchoice_clean),choices_survey$gname_label)
  
  #write.xlsx2(as.data.frame(choices_survey),gsub(".xlsx","_agg_method.xlsx",form_file_name), sheetName="choices", row.names=FALSE, na = "", append = TRUE)
  writeData(wb, sheet="choices",x=as.data.frame(choices_survey))
  saveWorkbook(wb, file=gsub(".xlsx","_agg_method.xlsx",form_file_name), overwrite = TRUE)
  
} #closed by Punya
NULL

 

