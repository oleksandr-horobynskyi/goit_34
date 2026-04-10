
--1.Вивести топ-3 клуби із найдорожчим захистом (Defender-*)

SELECT 
    club,
    sum(price) AS total_defense_value,
    count(*) AS defenders_count
FROM players
WHERE position LIKE 'Defender%'
GROUP BY club
ORDER BY total_defense_value DESC
LIMIT 3;


--2.У розрізі клубу та гравця порахувати, скільки гравців підписало контракт із клубом після нього

SELECT 
    club,
    name,
    (SELECT COUNT(*) 
     FROM players b2 
     WHERE b2.club = b1.club 
       AND b2.joined_club > b1.joined_club) AS players_joined_after_him
FROM players b1
ORDER BY club, joined_club ASC;

--3.Вибрати клуби, де середня вартість французьких гравців більша за 5 млн

SELECT 
    club,
    AVG(price) AS avg_french_player_price
FROM players
WHERE nationality = 'France'
GROUP BY club
HAVING AVG(price) > 5
ORDER BY avg_french_player_price DESC;

--4.Вибрати клуби, де частка німців вища за 90%

SELECT 
    club,
    COUNT(*) AS total_players,
    SUM(CASE WHEN nationality LIKE '%Germany%' THEN 1 ELSE 0 END) AS german_players,
    (SUM(CASE WHEN nationality LIKE '%Germany%' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS german_players_percentage
FROM players
GROUP BY club
HAVING german_players_percentage > 90
ORDER BY german_players_percentage DESC;


--5.Вибрати найдорожчого у своєму віці (на виході ім'я + вартість)

SELECT 
    name, 
    age, 
    price
FROM (
    SELECT 
        name, 
        age, 
        price,
        ROW_NUMBER() OVER(PARTITION BY age ORDER BY price DESC) AS row_num
    FROM players
    WHERE price IS NOT NULL
) AS ranked_table
WHERE row_num = 1
ORDER BY age ASC;

--6.Вибрати гравців, з вартістю у 1.5 рази більше, ніж у середньому за своєю позицією

SELECT 
    p1.name, 
    p1.position, 
    p1.price,
    (SELECT AVG(p2.price) 
     FROM players p2 
     WHERE p2.position = p1.position) AS avg_pos_price
FROM players p1
WHERE p1.price > 1.5 * (
    SELECT AVG(p2.price) 
    FROM players p2 
    WHERE p2.position = p1.position
)
ORDER BY p1.position, p1.price DESC;

-- варіант з використанням віконої функції

SELECT 
    name, 
    position, 
    price,
    avg_pos_price
FROM (
    SELECT 
        name, 
        position, 
        price,
        AVG(price) OVER(PARTITION BY position) AS avg_pos_price
    FROM players
) AS tab_avg_pos_price
WHERE price > 1.5 * avg_pos_price
ORDER BY position, price DESC;

-- 7.На якій позиції найважче отримати контракт з будь-якою компанією (наприклад, puma, adidas)

SELECT 
    position,
    COUNT(*) AS total_players,
    SUM(CASE WHEN outfitter IS NULL OR outfitter = '' THEN 1 ELSE 0 END) AS players_without_contract,
    ROUND(SUM(CASE WHEN outfitter IS NULL OR outfitter = '' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS no_contract_percentage
FROM players
GROUP BY position
ORDER BY no_contract_percentage DESC;

-- 8.Порахувати, в якій команді найперше закінчиться контракт у 5 гравців

WITH Ranked_Contracts AS (
    SELECT 
        club,
        contract_expires,
        ROW_NUMBER() OVER(PARTITION BY club ORDER BY contract_expires ASC) as player_rank
    FROM players
    WHERE contract_expires IS NOT NULL
)
SELECT 
    club,
    contract_expires AS fifth_player_expiry_date
FROM Ranked_Contracts
WHERE player_rank = 5
ORDER BY fifth_player_expiry_date ASC
 -- всього 10 клубів у яких закінчиться контракт у 5 гравців в один і той же день
LIMIT 11; 



-- 9. У якому віці гравці здебільшого виходять на пік своєї вартості

SELECT 
    age, 
    ROUND(AVG(price), 2) AS avg_price_value,
    COUNT(*) AS players_count,
    MAX(price) AS highest_price_in_age,
    SUM(price) AS total_price_in_age
FROM players
WHERE price IS NOT NULL
GROUP BY age
ORDER BY avg_price_value DESC
LIMIT 10;


--10. У якої команди найзіграніший склад (найдовше грають разом)

SELECT 
    club, 
    ROUND(AVG(date_diff('day', joined_club, current_date) / 365.0), 1) AS avg_years_in_club
FROM players
GROUP BY club
ORDER BY avg_years_in_club DESC
LIMIT 1;

--11. У яких командах є тезки

SELECT 
    club, 
    name, 
    COUNT(*) AS name_count
FROM players
GROUP BY club, name
HAVING COUNT(*) > 1
ORDER BY club, name;
-- повних тезків немає, але є гравці з однаковими іменами в одному кулбі. розібємо на імя та прізвище

SELECT 
    club, 
    split_part(name, ' ', 1) AS first_name, 
    COUNT(*) AS name_count
FROM players
GROUP BY club, split_part(name, ' ', 1)
HAVING COUNT(*) > 1
ORDER BY club;

--12. Вивести команди, де топ-3 гравці займають 50% платіжної відомості

WITH ranked_by_price AS (
    SELECT 
        club,
        name,
        price,
        ROW_NUMBER() OVER (PARTITION BY club ORDER BY price DESC) AS row_num
    FROM players
    WHERE price IS NOT NULL
),
team_stats AS (
    SELECT 
        club,
        sum(price) AS total_salary,
        sum(CASE WHEN row_num <= 3 THEN price ELSE 0 END) AS top3_salary
    FROM ranked_by_price
    GROUP BY club
)
SELECT 
    club,
    top3_salary,
    total_salary,
    round(top3_salary * 100.0 / total_salary, 2) AS top3_percentage
FROM team_stats
WHERE top3_percentage >= 50
ORDER BY top3_percentage DESC;
