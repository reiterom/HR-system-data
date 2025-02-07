/* Long-term work restrictions
    :employee_id {string}
    :minimum_days {number}
    :total_days_sum {number}
    :start_date {string}
    :end_date {string}
    :variable_input_table {identifier} - some departments have restricted access to the INPUT_TABLE for specific purposes
 */

-- Non-registered absences
select
    RESTRICTED_WORK_TYPE.DESCRIPTION as Work_Restriction_Type,
    (to_date(RESTRICTED_WORK_TYPE.END_DATE, 'YYYY-MM-DD') - to_date(RESTRICTED_WORK_TYPE.START_DATE, 'YYYY-MM-DD')) as Total_Days,
    RESTRICTED_WORK_TYPE.START_DATE as Start_Date,
    RESTRICTED_WORK_TYPE.END_DATE as End_Date
from
    RESTRICTED_WORK_TYPE
left join
    EMPLOYMENT_PERIODS on RESTRICTED_WORK_TYPE.PERIOD_ID = EMPLOYMENT_PERIODS.PERIOD_ID
left join
    EMPLOYEE_TABLE on EMPLOYMENT_PERIODS.EMPLOYEE_REF = EMPLOYEE_TABLE.EMPLOYEE_REF
where
    EMPLOYEE_TABLE.EMPLOYEE_NUMBER = :employee_id
    and ((RESTRICTED_WORK_TYPE.START_DATE between :start_date and :end_date)
        or (RESTRICTED_WORK_TYPE.END_DATE between :start_date and :end_date))

UNION ALL

-- Sickness and care leave
select
    SICKNESS_LEAVE.DESCRIPTION as Work_Restriction_Type,
    (to_date(:variable_input_table.END_DATE, 'YYYY-MM-DD') - to_date(:variable_input_table.START_DATE, 'YYYY-MM-DD')) as Total_Days,
    :variable_input_table.START_DATE as Start_Date,
    :variable_input_table.END_DATE as End_Date
from
    :variable_input_table
left join
    EMPLOYMENT_PERIODS on :variable_input_table.PERIOD_ID = EMPLOYMENT_PERIODS.PERIOD_ID
left join
    EMPLOYEE_TABLE on EMPLOYMENT_PERIODS.EMPLOYEE_REF = EMPLOYEE_TABLE.EMPLOYEE_REF
join
    SICKNESS_LEAVE on :variable_input_table.LEAVE_CODE = SICKNESS_LEAVE.LEAVE_CODE
join
    (
    select
        SUM(Total_Days) as Aggregate_Days -- Sum of all sickness days
    from
        (
            select
                (to_date(:variable_input_table.END_DATE, 'YYYY-MM-DD') - to_date(:variable_input_table.START_DATE, 'YYYY-MM-DD')) as Total_Days
            from
                :variable_input_table
            left join
                EMPLOYMENT_PERIODS on :variable_input_table.PERIOD_ID = EMPLOYMENT_PERIODS.PERIOD_ID
            left join
                EMPLOYEE_TABLE on EMPLOYMENT_PERIODS.EMPLOYEE_REF = EMPLOYEE_TABLE.EMPLOYEE_REF
            join
                SICKNESS_LEAVE on :variable_input_table.LEAVE_CODE = SICKNESS_LEAVE.LEAVE_CODE
            where
                :variable_input_table.LEAVE_CODE in (51, 53, 56)
                and EMPLOYEE_TABLE.EMPLOYEE_NUMBER = :employee_id
        )
    ) on 1=1
where
    :variable_input_table.LEAVE_CODE in (51, 53, 56)
    and EMPLOYEE_TABLE.EMPLOYEE_NUMBER = :employee_id
    and ((:variable_input_table.START_DATE between :start_date and :end_date)
        or (:variable_input_table.END_DATE between :start_date and :end_date))
    and ((to_date(:variable_input_table.END_DATE, 'YYYY-MM-DD') - to_date(:variable_input_table.START_DATE, 'YYYY-MM-DD') > :minimum_days) -- Minimum days for sickness
            or Aggregate_Days > :total_days_sum)
