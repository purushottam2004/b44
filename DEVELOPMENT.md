## Plan

- I'm developing a card game which I can play with my friends later. 
- The technical specifications are as follows
    - It is web based using react, and a fixed layout on full screen, to that it gives app like experience
    - It will have room based system
    - It will consist of some common codebase and then multiple card games
    - backend in python, frontend in typescript, supabase as the postgres  database
    - want to levarage supabase for the realtime thing, but want to write the game rules in the python backend. like supabase for game's state management basically (source of truth) which python sees and processes, typescript sees and displays
    - Game move loop like :
        - user plays a move (it happens on frontend instantly) -> move is sent to backend -> backend validates and updates the db -> db sends realtime update to frontend -> if validated by python and updated in db then good , otherwise backend says to frontend error and frontend rolls back the move and says Move Not Valid, no supabase involved in this case

- Philosophy behind is as follows
    - It's not a startup or saas, it's for personal use of me and my friends
    - There are many card games which I want , but you won't know probably, hence let it be generalistic , any kind of card rules I can make in my backend, let frontend just handle the rendering type stuff. For initial example let's have callbreak

- DB SCHEMA
    - Auth Realted Tables
        - auth.users - already present in supabase
        - public.users - to be made to store extra info about users with foreign key to auth.users as it's primary key (uuid)
    
    - Game State Management Tables
        - rooms : one room can hold multiple game_rounds
        - game_rounds : contains a game round which indeed contains game moves game type etc. 
        - game_moves  : contains what card dispatched etc. thing various types of game moves can be there, like picking from deck , throwing card etc. etc. 
        - game_players : live in a room , hold the cards
        
         