/* History of employment contracts
    :employee_id {string}
    :fixed_term {number, string}
 */

-- Selects the row corresponding to the latest contract for a single employment (an employee may have multiple contracts if they have been employed before)
with LatestContracts as (
    select
        EMPLOYMENT_TABLE.EMPLOYMENT_ID,
        MAX(EMPLOYMENT_DETAILS_HIST.DETAIL_ORDER) as latest_contract
    from
        EMPLOYMENT_TABLE
    join
        PERSON_TABLE on EMPLOYMENT_TABLE.PERSON_ID = PERSON_TABLE.PERSON_ID
    join
        EMPLOYMENT_DETAILS_HIST on EMPLOYMENT_TABLE.EMPLOYMENT_ID = EMPLOYMENT_DETAILS_HIST.EMPLOYMENT_ID
    where to_char(PERSON_TABLE.EMPLOYEE_NUMBER) = :employee_id
        and EMPLOYMENT_TABLE.EMPLOYMENT_TYPE = 1
    group by EMPLOYMENT_TABLE.EMPLOYMENT_ID
)
select
    EMPLOYMENT_DETAILS_HIST.START_DATE as START_DATE,
-- For the latest contract, the end date is taken from the column END_DATE, because the DETAIL_END_DATE column has the value 3333-03-03 even for fixed-term contracts
    case
        when EMPLOYMENT_DETAILS_HIST.FIXED_TERM = 1
            and EMPLOYMENT_DETAILS_HIST.DETAIL_ORDER = LatestContracts.latest_contract
            then EMPLOYMENT_DETAILS_HIST.END_DATE
            else EMPLOYMENT_DETAILS_HIST.DETAIL_END_DATE
     end as END_DATE,
    ORGANISATION_UNIT.SHORT_NAME as WORKPLACE,
    EMPLOYMENT_DETAILS_HIST.JOB_TITLE as JOB_CATEGORY,
    EMPLOYMENT_POSITION_HIST.PAY_GRADE,
    EMPLOYMENT_POSITION_HIST.WORKLOAD,
    EMPLOYMENT_DETAILS_HIST.FIXED_TERM
from
    EMPLOYMENT_TABLE
join
    PERSON_TABLE on EMPLOYMENT_TABLE.PERSON_ID = PERSON_TABLE.PERSON_ID
join
    EMPLOYMENT_DETAILS_HIST on EMPLOYMENT_TABLE.EMPLOYMENT_ID = EMPLOYMENT_DETAILS_HIST.EMPLOYMENT_ID
join
    EMPLOYMENT_POSITION_HIST on EMPLOYMENT_DETAILS_HIST.EMPLOYMENT_DETAIL_ID = EMPLOYMENT_POSITION_HIST.EMPLOYMENT_DETAIL_ID
join
    ORGANISATION_UNIT on EMPLOYMENT_DETAILS_HIST.WORKPLACE_ID = ORGANISATION_UNIT.UNIT_ID
left join
    LatestContracts on EMPLOYMENT_TABLE.EMPLOYMENT_ID = LatestContracts.EMPLOYMENT_ID
                    and EMPLOYMENT_DETAILS_HIST.DETAIL_ORDER = LatestContracts.latest_contract
where
    to_char(PERSON_TABLE.EMPLOYEE_NUMBER) = :employee_id
  -- If the variable is not null, only select fixed-term contracts
    and (
        (:fixed_term is not null and EMPLOYMENT_DETAILS_HIST.FIXED_TERM = 1)
        or (:fixed_term is null and EMPLOYMENT_DETAILS_HIST.FIXED_TERM = EMPLOYMENT_DETAILS_HIST.FIXED_TERM)
    )
order by START_DATE
