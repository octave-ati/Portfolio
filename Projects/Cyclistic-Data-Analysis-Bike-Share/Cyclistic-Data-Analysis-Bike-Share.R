install.packages("bigrquery")
install.packages("tidyverse")
install.packages("wk")
install.packages("lubridate")

library(bigrquery)
library(tidyverse)
library(wk)
library(lubridate)
Sys.setlocale("LC_TIME", "English")

con <- dbConnect(
  bigrquery::bigquery(),
  project = "cyclistic-case-study-349908",
  dataset = "cyclistic",
  billing = "cyclistic-case-study-349908"
)

trips = tbl(con,"trips")
glimpse(trips)



#Downloading Length information from Bigquery and creating Month_Year Column
#The collect() is required to pull data from Bigquery and store it locally
length_info <-
  trips %>% 
  select(member_casual,started_at,length_min,rideable_type) %>% 
  collect() %>% 
  mutate(month_year = factor(format(started_at, "%b-%y"), levels = 
           c("May-21","Jun-21","Jul-21","Aug-21","Sep-21","Oct-21","Nov-21","Dec-21","Jan-22","Feb-22","Mar-22","Apr-22")))

length_info <-
  length_info %>% 
  mutate(Date = date(started_at))
         
#Calculate the number of rides per user type

length_info %>% 
  group_by(month_year,member_casual) %>% 
  summarize(rides=n()) %>% 
  ggplot(aes(x=month_year,y=rides,group=member_casual,color=member_casual)) + geom_point(size=2) + geom_line(size=1.5) + 
  labs(color="Member Type", x="Month-Year", y="Number of Rides") + scale_y_continuous(labels = scales::comma) 
length_info %>% 
  group_by(Date,member_casual) %>% 
  summarize(rides=n()) %>% 
  ggplot(aes(x=Date,y=rides,group=member_casual,color=member_casual)) + geom_point() %>% 
  labs(color="Member Type", x="Date", y="Number of Rides") + scale_y_continuous(labels = scales::comma)+ 
  geom_smooth() + scale_x_date(date_labels="%b-%y",date_breaks  ="1 month",expand = c(0,0))+
  ggtitle("Rides per day for each Member Type") 



# Creating Length Per Month graph
length_info %>% 
  filter(length_min<1440) %>% 
  group_by(month_year,member_casual) %>% 
  summarise(average_length = mean(length_min)) %>% 
  ggplot() + geom_col(aes(x=month_year,y=average_length,fill=member_casual),position = 'dodge') + 
  labs(fill="Member Type", x="Month", y="Ride Length")

# Comparing Length to bike_type
length_info %>% 
  filter(length_min<1440) %>% 
  group_by(rideable_type,member_casual) %>% 
  summarise(average_length = mean(length_min)) %>% 
  ggplot() + geom_col(aes(x=rideable_type,y=average_length,fill=member_casual),position = 'dodge') + 
  labs(fill="Member Type", x="Bike Type", y="Ride Length")

#Finding out why only casual members use docked_bikes
length_info %>% 
  filter(rideable_type == "docked_bike") %>% 
  summarise(max_date = max(started_at), min_date = min(started_at))
#Returns all available dates

distance_info <-
  trips %>% 
  select(member_casual,started_at,distance_m,rideable_type) %>% 
  collect() %>% 
  mutate(month_year = factor(format(started_at, "%b-%y"), levels = 
                               c("May-21","Jun-21","Jul-21","Aug-21","Sep-21","Oct-21","Nov-21","Dec-21","Jan-22","Feb-22","Mar-22","Apr-22")))

#Creating distance per month graph
distance_info %>% 
  filter(distance_m >= 0) %>% 
  group_by(month_year,member_casual) %>% 
  summarise(average_dist = mean(distance_m)) %>% 
  ggplot() + geom_col(aes(x=month_year,y=average_dist,fill=member_casual),position = 'dodge') + 
  labs(fill="Member Type", x="Month", y="Distance from start to end station")
#Slightly higher distance for casual members, but nothing significant, see Graph
#Storing total number of rides for each type of user
casual_count = tally(distance_info,member_casual == "casual")[[1,1]]
member_count = tally(distance_info, member_casual == "member")[[1,1]]

#Type of bike used in percent for each type
distance_info %>% 
  select(member_casual, month_year, rideable_type) %>% 
  group_by(rideable_type,member_casual) %>% 
  summarise(bike_count = n()) %>% 
  mutate(bike_count = ifelse (member_casual == "member", 100*bike_count/tally(distance_info, member_casual == "member")[[1,1]],
                              100*bike_count/tally(distance_info,member_casual == "casual")[[1,1]])) %>% 
  ggplot() + geom_bar(aes(x="",y=bike_count,fill=rideable_type),stat="identity", width=1) +
  coord_polar("y", start=0) + facet_wrap(~member_casual)

#Removing the useless docked_bike type :

distance_info %>% 
  select(member_casual, month_year, rideable_type) %>% 
  group_by(rideable_type,member_casual) %>% 
  summarise(bike_count = n()) %>% 
  mutate(bike_count = ifelse (member_casual == "member", 100*bike_count/tally(distance_info, member_casual == "member")[[1,1]],
                              100*bike_count/tally(distance_info,member_casual == "casual")[[1,1]])) %>% 
  mutate(rideable_type = ifelse(rideable_type == "docked_bike", "electric_bike", rideable_type)) %>% 
  ggplot() + geom_bar(aes(x="",y=bike_count,fill=rideable_type),stat="identity", width=1) +
  coord_polar("y", start=0) + facet_wrap(~member_casual)
  
#5 most used stations
#Downloading a station database from BigQuery
station_db <-
  trips %>% 
  select(member_casual,started_at,start_station_name,end_station_name,rideable_type) %>% 
  filter(!is.na(start_station_name)) %>% 
  collect() %>% 
  mutate(month_year = factor(format(started_at, "%b-%y"), levels = 
                               c("May-21","Jun-21","Jul-21","Aug-21","Sep-21","Oct-21","Nov-21","Dec-21","Jan-22","Feb-22","Mar-22","Apr-22")))

#We create a variable to make labelling easier in ggplot graphs, then apply it using the "as_labeller" function
member_names <- c(
  `casual` = "Casual",
  `member` = "Annual Member"
)

#Showing top 5 stations for each category
station_db %>% 
  select(member_casual,month_year,start_station_name) %>%
  group_by(member_casual,start_station_name) %>% 
  summarize(ride_count = n()) %>%
  mutate(ride_perc = ifelse(member_casual == "member", 100*ride_count/tally(station_db,member_casual == "member")[[1,1]],
        100*ride_count/tally(station_db,member_casual == "casual")[[1,1]])) %>% 
  arrange(member_casual, desc(ride_perc)) %>% 
  group_by(member_casual) %>% 
  mutate(rank = rank(-ride_perc)) %>% 
  filter(rank<=5) %>% 
  ggplot(aes(x=start_station_name, y=ride_perc, fill=member_casual)) + geom_col() +
  facet_wrap(~member_casual,scales = "free_x", labeller = as_labeller(member_names)) + 
  aes(stringr::str_wrap(start_station_name, 15), ride_perc) + xlab(NULL) +
  ylab("Percentage of total rides") + ggtitle("Top 5 stations") + labs(fill="Member type")
  
#scale_x_discrete(labels = abbreviate) could have been used to abbreviate station names
#tally calculates the number of total rides per user type in order to calculate percent.
#We then use the rank function to find the top 5 stations for each user type.
#We use the "scales = "free_x"" argument to remove empty labels in our 2 facets
# (stations which are in the top 5 for one category but not the other)

#Now we will create a table that we will import into tableau to create a heatmap of stations
#First let's import part of our database so we can upload it into Tableau :

station_heatmap <-
  trips %>% 
  select(member_casual,start_station_id) %>% 
  filter(!is.na(start_station_name)) %>% 
  filter(!is.na(start_loc_text)) %>%
  collect () %>% 
  mutate(month_year = factor(format(started_at, "%b-%y"), levels = 
                               c("May-21","Jun-21","Jul-21","Aug-21","Sep-21","Oct-21","Nov-21","Dec-21","Jan-22","Feb-22","Mar-22","Apr-22")))

#Rowwie is necessary because otherwise our latitude and longitude splits would only take the first instance of start_loc_text, leaving us
#with the same coordinates for all rows
#Now we can group the results by month-year and calculate the number of rides

#Updating station_info to include start_station_loc

ALTER TABLE cyclistic.station_info
ADD COLUMN IF NOT EXISTS Latitude FLOAT64,
ADD COLUMN IF NOT EXISTS Longitude FLOAT64;

UPDATE cyclistic.station_info
SET station_loc_text = CONCAT(ST_Y(station_loc),",",ST_X(station_loc)),
    Latitude = CAST(ST_Y(station_loc) AS FLOAT64),
    Longitude = CAST(ST_X(station_loc) AS FLOAT64)
WHERE TRUE; 

station_info <- tbl(con,"station_info") %>% collect()


heatmap_export <-
  station_heatmap %>% 
    select(member_casual,start_station_id, month_year) %>% 
    group_by (member_casual,start_station_id,month_year) %>% 
    summarize(rides = n())

heatmap_final <-
  heatmap_export %>%
  setNames(c("Member type","station_id","month_year","rides")) %>% 
  full_join(station_info,by="station_id")
  
#Now we can download this table as a CSV for easy import into Tableau

write.csv(heatmap_final,"heatmap_final.csv")

#We now want to find the top 20 stations each month for each category
ranked_heatmap <-
  heatmap_final %>% 
  arrange(`Member type`, month_year, desc(rides)) %>% 
  group_by(`Member type`, month_year) %>% 
  mutate(rank = rank(-rides)) %>% 
  filter(rank<=20) 

#Stations in the top 30 for both categories

ranked_heatmap <-
  heatmap_final %>% 
#filter(month_year!="Jun-21" & month_year!= "Jul-21" & month_year!= "Aug-21")%>% 
  group_by(`Member type`,station_id) %>% 
  summarise(rides = sum(rides)) %>% 
  arrange(`Member type`, desc(rides)) %>% 
  group_by(`Member type`) %>% 
  mutate(rank = rank(-rides)) %>% 
  filter(rank<=30) %>% 
  group_by(station_id) %>% 
  filter(n()>1) %>% 
  summarise(total_rides = sum(rides), average_rank = mean(rank)) %>% 
  left_join(station_info,by="station_id") %>% 
  arrange(average_rank)

write.csv(ranked_heatmap,"ranked_heatmap.csv")