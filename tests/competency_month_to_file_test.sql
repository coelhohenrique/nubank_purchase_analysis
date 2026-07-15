select
    source_file
from {{ ref('int__nubank_transactions') }}
group by source_file
having count(distinct competency_month) > 1