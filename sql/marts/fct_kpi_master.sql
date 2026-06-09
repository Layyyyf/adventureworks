{{
  config(
    materialized = 'table',
    description  = 'Master KPI summary — one row, all-time business KPIs for dashboard scorecards'
  )
}}

with sales as (
    select
        order_number,
        customer_key,
        order_date,
        order_quantity,
        order_line_revenue,
        order_line_cost,
        order_line_profit
    from {{ ref('fct_sales') }}
),

returns as (
    select
        return_quantity,
        return_value
    from {{ ref('fct_returns') }}
),

-- Customer lifetime stats for retention KPIs
customer_lifetime as (
    select
        customer_key,
        count(distinct order_number)        as lifetime_orders,
        sum(order_line_revenue)             as lifetime_revenue
    from sales
    group by customer_key
),

-- All-time totals from returns
returns_totals as (
    select
        sum(return_quantity)                as total_units_returned,
        sum(return_value)                   as total_return_value
    from returns
),

final as (
    select

        -- ── Date range ──────────────────────────────────────────────
        min(s.order_date)                                       as data_start_date,
        max(s.order_date)                                       as data_end_date,
        datediff(day, min(s.order_date), max(s.order_date))     as data_span_days,

        -- ── Volume KPIs ─────────────────────────────────────────────
        count(distinct s.order_number)                          as total_orders,
        count(*)                                                as total_line_items,
        sum(s.order_quantity)                                   as total_units_sold,
        count(distinct s.customer_key)                          as total_unique_customers,

        -- ── Revenue KPIs ────────────────────────────────────────────
        round(sum(s.order_line_revenue), 2)                     as total_gross_revenue,
        round(
            sum(s.order_line_revenue)
            / nullif(count(distinct s.order_number), 0)
        , 2)                                                    as avg_order_value,
        round(
            sum(s.order_line_revenue)
            / nullif(count(distinct s.customer_key), 0)
        , 2)                                                    as avg_revenue_per_customer,
        round(
            sum(s.order_line_revenue)
            / nullif(sum(s.order_quantity), 0)
        , 2)                                                    as avg_selling_price_per_unit,

        -- ── Profitability KPIs ──────────────────────────────────────
        round(sum(s.order_line_cost), 2)                        as total_cogs,
        round(sum(s.order_line_profit), 2)                      as total_gross_profit,
        round(
            100.0 * sum(s.order_line_profit)
            / nullif(sum(s.order_line_revenue), 0)
        , 2)                                                    as gross_margin_pct,
        round(
            sum(s.order_line_profit)
            / nullif(count(distinct s.order_number), 0)
        , 2)                                                    as avg_profit_per_order,

        -- ── Returns KPIs ────────────────────────────────────────────
        max(rt.total_units_returned)                            as total_units_returned,
        round(max(rt.total_return_value), 2)                    as total_return_value,
        round(
            100.0 * max(rt.total_units_returned)
            / nullif(sum(s.order_quantity), 0)
        , 2)                                                    as return_rate_pct,

        -- ── Customer behaviour KPIs ─────────────────────────────────
        round(
            cast(count(distinct s.order_number) as float)
            / nullif(count(distinct s.customer_key), 0)
        , 2)                                                    as avg_orders_per_customer,
        round(
            cast(sum(s.order_quantity) as float)
            / nullif(count(distinct s.order_number), 0)
        , 2)                                                    as avg_units_per_order,
        count(distinct case when cl.lifetime_orders > 1
            then s.customer_key end)                            as repeat_customers,
        count(distinct case when cl.lifetime_orders = 1
            then s.customer_key end)                            as one_time_customers,
        round(
            100.0 * count(distinct case when cl.lifetime_orders > 1
                then s.customer_key end)
            / nullif(count(distinct s.customer_key), 0)
        , 2)                                                    as repeat_customer_rate_pct,
        round(avg(cl.lifetime_revenue), 2)                      as avg_customer_ltv

    from sales s
    cross join returns_totals rt
    left join customer_lifetime cl on s.customer_key = cl.customer_key
)

select * from final
