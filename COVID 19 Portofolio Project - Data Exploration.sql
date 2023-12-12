
SELECT *
FROM Covid19Project..CovidDeaths$
WHERE continent is not null
ORDER BY 3,4

SELECT *
FROM Covid19Project..CovidVaccinations$
WHERE continent is not null
ORDER BY 3,4

-- Select Data that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From Covid19Project..CovidDeaths$
WHERE continent is not null
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, total_cases, total_deaths,
	(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM Covid19Project..CovidDeaths$
-- Where location like %american%
WHERE continent is not null
ORDER BY 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
SELECT Location, date, Population, total_cases,   
	(CONVERT(float, total_cases) / NULLIF(population, 0))*100 as PercentPopulationInfected
FROM Covid19Project..CovidDeaths$
-- Where location like %american%
WHERE continent is not null
order by 1,2

-- Countries with Highest Infection Rate compared to Population
SELECT Location, population, 
	MAX(total_cases) AS HighestInfectionCount,
	MAX (total_cases/population)*100 AS PercentPopulationInfected
FROM Covid19Project..CovidDeaths$
-- Where location like %american%
WHERE continent is not null
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM Covid19Project..CovidDeaths$
-- Where location like %american%
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC

-------------------------------------------------------------------------------------------------------------------------------------------
-- BREAKING DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM Covid19Project..CovidDeaths$
-- Where location like %american%
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-------------------------------------------------------------------------------------------------------------------------------------------
-- GLOBAL NUMBERS

SELECT SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Covid19Project..CovidDeaths$
-- Where location like %american%
WHERE continent is not null
GROUP BY date 
ORDER BY 1, 2


-------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------
-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM Covid19Project..CovidDeaths$ dea
JOIN Covid19Project..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM Covid19Project..CovidDeaths$ dea
JOIN Covid19Project..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM Covid19Project..CovidDeaths$ dea
JOIN Covid19Project..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
--WHERE dea.continent is not null 
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
FROM Covid19Project..CovidDeaths$ dea
JOIN Covid19Project..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 


SELECT *
FROM PercentPopulationVaccinated