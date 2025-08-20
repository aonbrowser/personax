--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Ubuntu 14.18-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.18 (Ubuntu 14.18-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.user_subscriptions DROP CONSTRAINT IF EXISTS user_subscriptions_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.user_subscriptions DROP CONSTRAINT IF EXISTS user_subscriptions_plan_id_fkey;
ALTER TABLE IF EXISTS ONLY public.user_lifecoaching_notes DROP CONSTRAINT IF EXISTS user_lifecoaching_notes_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.usage_tracking DROP CONSTRAINT IF EXISTS usage_tracking_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.usage_tracking DROP CONSTRAINT IF EXISTS usage_tracking_subscription_id_fkey;
ALTER TABLE IF EXISTS ONLY public.scores DROP CONSTRAINT IF EXISTS scores_assessment_id_fkey;
ALTER TABLE IF EXISTS ONLY public.responses DROP CONSTRAINT IF EXISTS responses_item_id_fkey;
ALTER TABLE IF EXISTS ONLY public.responses DROP CONSTRAINT IF EXISTS responses_assessment_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_owner_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_dyad_id_fkey;
ALTER TABLE IF EXISTS ONLY public.people DROP CONSTRAINT IF EXISTS people_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.monthly_usage_summary DROP CONSTRAINT IF EXISTS monthly_usage_summary_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.monthly_usage_summary DROP CONSTRAINT IF EXISTS monthly_usage_summary_subscription_id_fkey;
ALTER TABLE IF EXISTS ONLY public.messages DROP CONSTRAINT IF EXISTS messages_session_id_fkey;
ALTER TABLE IF EXISTS ONLY public.language_incidents DROP CONSTRAINT IF EXISTS language_incidents_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.iap_purchases DROP CONSTRAINT IF EXISTS iap_purchases_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.payg_purchases DROP CONSTRAINT IF EXISTS fk_payg_iap_transaction;
ALTER TABLE IF EXISTS ONLY public.user_subscriptions DROP CONSTRAINT IF EXISTS fk_iap_transaction;
ALTER TABLE IF EXISTS ONLY public.dyads DROP CONSTRAINT IF EXISTS dyads_b_person_id_fkey;
ALTER TABLE IF EXISTS ONLY public.dyads DROP CONSTRAINT IF EXISTS dyads_a_person_id_fkey;
ALTER TABLE IF EXISTS ONLY public.dyad_scores DROP CONSTRAINT IF EXISTS dyad_scores_dyad_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_sessions DROP CONSTRAINT IF EXISTS chat_sessions_dyad_id_fkey;
ALTER TABLE IF EXISTS ONLY public.assessments DROP CONSTRAINT IF EXISTS assessments_person_id_fkey;
ALTER TABLE IF EXISTS ONLY public.analysis_results DROP CONSTRAINT IF EXISTS analysis_results_user_id_fkey;
DROP TRIGGER IF EXISTS update_monthly_usage_on_insert ON public.usage_tracking;
DROP TRIGGER IF EXISTS trigger_update_monthly_usage ON public.usage_tracking;
DROP INDEX IF EXISTS public.idx_user_subscriptions_user_id;
DROP INDEX IF EXISTS public.idx_user_subscriptions_status;
DROP INDEX IF EXISTS public.idx_user_subscriptions_end_date;
DROP INDEX IF EXISTS public.idx_usage_tracking_user_id;
DROP INDEX IF EXISTS public.idx_usage_tracking_created_at;
DROP INDEX IF EXISTS public.idx_resp_item;
DROP INDEX IF EXISTS public.idx_resp_assessment;
DROP INDEX IF EXISTS public.idx_people_user;
DROP INDEX IF EXISTS public.idx_payg_purchases_user_id;
DROP INDEX IF EXISTS public.idx_monthly_usage_user_month;
DROP INDEX IF EXISTS public.idx_lifecoaching_notes_user_id;
DROP INDEX IF EXISTS public.idx_iap_user;
DROP INDEX IF EXISTS public.idx_iap_transaction;
DROP INDEX IF EXISTS public.idx_analysis_results_user_id;
DROP INDEX IF EXISTS public.idx_analysis_results_status;
DROP INDEX IF EXISTS public.idx_analysis_results_created_at;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY public.user_subscriptions DROP CONSTRAINT IF EXISTS user_subscriptions_pkey;
ALTER TABLE IF EXISTS ONLY public.user_lifecoaching_notes DROP CONSTRAINT IF EXISTS user_lifecoaching_notes_pkey;
ALTER TABLE IF EXISTS ONLY public.usage_tracking DROP CONSTRAINT IF EXISTS usage_tracking_pkey;
ALTER TABLE IF EXISTS ONLY public.token_costs DROP CONSTRAINT IF EXISTS token_costs_pkey;
ALTER TABLE IF EXISTS ONLY public.subscription_plans DROP CONSTRAINT IF EXISTS subscription_plans_pkey;
ALTER TABLE IF EXISTS ONLY public.scores DROP CONSTRAINT IF EXISTS scores_pkey;
ALTER TABLE IF EXISTS ONLY public.responses DROP CONSTRAINT IF EXISTS responses_pkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_pkey;
ALTER TABLE IF EXISTS ONLY public.people DROP CONSTRAINT IF EXISTS people_pkey;
ALTER TABLE IF EXISTS ONLY public.payg_purchases DROP CONSTRAINT IF EXISTS payg_purchases_pkey;
ALTER TABLE IF EXISTS ONLY public.payg_pricing DROP CONSTRAINT IF EXISTS payg_pricing_pkey;
ALTER TABLE IF EXISTS ONLY public.monthly_usage_summary DROP CONSTRAINT IF EXISTS monthly_usage_summary_user_id_month_year_key;
ALTER TABLE IF EXISTS ONLY public.monthly_usage_summary DROP CONSTRAINT IF EXISTS monthly_usage_summary_pkey;
ALTER TABLE IF EXISTS ONLY public.messages DROP CONSTRAINT IF EXISTS messages_pkey;
ALTER TABLE IF EXISTS ONLY public.language_incidents DROP CONSTRAINT IF EXISTS language_incidents_pkey;
ALTER TABLE IF EXISTS ONLY public.items DROP CONSTRAINT IF EXISTS items_pkey;
ALTER TABLE IF EXISTS ONLY public.iap_purchases DROP CONSTRAINT IF EXISTS iap_purchases_transaction_id_key;
ALTER TABLE IF EXISTS ONLY public.iap_purchases DROP CONSTRAINT IF EXISTS iap_purchases_pkey;
ALTER TABLE IF EXISTS ONLY public.iap_products DROP CONSTRAINT IF EXISTS iap_products_platform_product_id_key;
ALTER TABLE IF EXISTS ONLY public.iap_products DROP CONSTRAINT IF EXISTS iap_products_pkey;
ALTER TABLE IF EXISTS ONLY public.dyads DROP CONSTRAINT IF EXISTS dyads_pkey;
ALTER TABLE IF EXISTS ONLY public.dyad_scores DROP CONSTRAINT IF EXISTS dyad_scores_pkey;
ALTER TABLE IF EXISTS ONLY public.chat_sessions DROP CONSTRAINT IF EXISTS chat_sessions_pkey;
ALTER TABLE IF EXISTS ONLY public.assessments DROP CONSTRAINT IF EXISTS assessments_pkey;
ALTER TABLE IF EXISTS ONLY public.analysis_results DROP CONSTRAINT IF EXISTS analysis_results_pkey;
ALTER TABLE IF EXISTS public.responses ALTER COLUMN id DROP DEFAULT;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.user_subscriptions;
DROP TABLE IF EXISTS public.user_lifecoaching_notes;
DROP TABLE IF EXISTS public.usage_tracking;
DROP TABLE IF EXISTS public.token_costs;
DROP TABLE IF EXISTS public.subscription_plans;
DROP TABLE IF EXISTS public.scores;
DROP SEQUENCE IF EXISTS public.responses_id_seq;
DROP TABLE IF EXISTS public.responses;
DROP TABLE IF EXISTS public.reports;
DROP TABLE IF EXISTS public.people;
DROP TABLE IF EXISTS public.payg_purchases;
DROP TABLE IF EXISTS public.payg_pricing;
DROP TABLE IF EXISTS public.monthly_usage_summary;
DROP TABLE IF EXISTS public.messages;
DROP TABLE IF EXISTS public.language_incidents;
DROP TABLE IF EXISTS public.items;
DROP TABLE IF EXISTS public.iap_purchases;
DROP TABLE IF EXISTS public.iap_products;
DROP TABLE IF EXISTS public.dyads;
DROP TABLE IF EXISTS public.dyad_scores;
DROP TABLE IF EXISTS public.chat_sessions;
DROP TABLE IF EXISTS public.assessments;
DROP TABLE IF EXISTS public.analysis_results;
DROP FUNCTION IF EXISTS public.update_subscription_credits(p_subscription_id text, p_service_type text, p_amount integer);
DROP FUNCTION IF EXISTS public.update_monthly_usage_summary();
DROP FUNCTION IF EXISTS public.update_monthly_usage();
DROP FUNCTION IF EXISTS public.process_iap_renewal(p_user_id uuid, p_transaction_id character varying, p_product_id character varying, p_platform character varying);
DROP FUNCTION IF EXISTS public.get_user_active_subscriptions(p_user_id uuid);
DROP EXTENSION IF EXISTS "uuid-ossp";
--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: get_user_active_subscriptions(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_active_subscriptions(p_user_id uuid) RETURNS TABLE(subscription_id uuid, plan_id text, start_date timestamp without time zone, end_date timestamp without time zone, status text, credits_remaining jsonb, is_primary boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        us.id as subscription_id,
        us.plan_id,
        us.start_date,
        us.end_date,
        us.status,
        us.credits_remaining,
        us.is_primary
    FROM user_subscriptions us
    WHERE us.user_id = p_user_id 
        AND us.status = 'active'
        AND (us.end_date IS NULL OR us.end_date > NOW())
    ORDER BY 
        us.end_date ASC NULLS LAST,
        us.created_at ASC;
END;
$$;


--
-- Name: process_iap_renewal(uuid, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.process_iap_renewal(p_user_id uuid, p_transaction_id character varying, p_product_id character varying, p_platform character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_plan_id VARCHAR(50);
  v_plan RECORD;
BEGIN
  -- Get plan ID from product configuration
  SELECT plan_id INTO v_plan_id
  FROM iap_products
  WHERE platform = p_platform AND product_id = p_product_id;
  
  IF v_plan_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Get plan details
  SELECT * INTO v_plan
  FROM subscription_plans
  WHERE id = v_plan_id;
  
  IF v_plan IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Extend or create subscription
  INSERT INTO user_subscriptions (
    user_id,
    plan_id,
    start_date,
    end_date,
    status,
    credits_remaining,
    iap_transaction_id
  ) VALUES (
    p_user_id,
    v_plan_id,
    NOW(),
    NOW() + INTERVAL '1 month',
    'active',
    jsonb_build_object(
      'self_reanalysis', v_plan.self_reanalysis_limit,
      'other_analysis', v_plan.other_analysis_limit,
      'relationship_analysis', v_plan.relationship_analysis_limit,
      'coaching_tokens', v_plan.coaching_tokens_limit
    ),
    p_transaction_id
  )
  ON CONFLICT (user_id, plan_id) 
  DO UPDATE SET
    end_date = EXCLUDED.end_date,
    status = 'active',
    credits_remaining = EXCLUDED.credits_remaining,
    iap_transaction_id = EXCLUDED.iap_transaction_id;
  
  RETURN TRUE;
END;
$$;


--
-- Name: update_monthly_usage(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_monthly_usage() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO monthly_usage_summary (
    user_id, 
    subscription_id,
    month_year,
    self_analysis_count,
    self_reanalysis_count,
    other_analysis_count,
    relationship_analysis_count,
    coaching_tokens_used,
    total_cost_usd,
    total_charged_usd
  ) VALUES (
    NEW.user_id,
    NEW.subscription_id,
    TO_CHAR(NEW.created_at, 'YYYY-MM'),
    CASE WHEN NEW.service_type = 'self_analysis' AND NOT NEW.is_reanalysis THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'self_analysis' AND NEW.is_reanalysis THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'other_analysis' THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'relationship_analysis' THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'coaching' THEN NEW.tokens_used ELSE 0 END,
    COALESCE(NEW.cost_usd, 0),
    COALESCE(NEW.price_charged_usd, 0)
  )
  ON CONFLICT (user_id, month_year) DO UPDATE SET
    self_analysis_count = monthly_usage_summary.self_analysis_count + 
      CASE WHEN NEW.service_type = 'self_analysis' AND NOT NEW.is_reanalysis THEN 1 ELSE 0 END,
    self_reanalysis_count = monthly_usage_summary.self_reanalysis_count + 
      CASE WHEN NEW.service_type = 'self_analysis' AND NEW.is_reanalysis THEN 1 ELSE 0 END,
    other_analysis_count = monthly_usage_summary.other_analysis_count + 
      CASE WHEN NEW.service_type = 'other_analysis' THEN 1 ELSE 0 END,
    relationship_analysis_count = monthly_usage_summary.relationship_analysis_count + 
      CASE WHEN NEW.service_type = 'relationship_analysis' THEN 1 ELSE 0 END,
    coaching_tokens_used = monthly_usage_summary.coaching_tokens_used + 
      CASE WHEN NEW.service_type = 'coaching' THEN NEW.tokens_used ELSE 0 END,
    total_cost_usd = monthly_usage_summary.total_cost_usd + COALESCE(NEW.cost_usd, 0),
    total_charged_usd = monthly_usage_summary.total_charged_usd + COALESCE(NEW.price_charged_usd, 0),
    updated_at = CURRENT_TIMESTAMP;
  
  RETURN NEW;
END;
$$;


--
-- Name: update_monthly_usage_summary(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_monthly_usage_summary() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Insert or update monthly summary
  INSERT INTO monthly_usage_summary (
    user_id,
    month_year,
    subscription_id,
    self_analysis_count,
    self_reanalysis_count,
    other_analysis_count,
    relationship_analysis_count,
    coaching_tokens_used,
    total_cost_usd,
    total_charged_usd
  )
  VALUES (
    NEW.user_id,
    TO_CHAR(NEW.created_at, 'YYYY-MM'),
    NEW.subscription_id,
    CASE WHEN NEW.service_type = 'self_analysis' AND NOT NEW.is_reanalysis THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'self_analysis' AND NEW.is_reanalysis THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'other_analysis' THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'relationship_analysis' THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'coaching' THEN NEW.tokens_used ELSE 0 END,
    NEW.cost_usd,
    NEW.price_charged_usd
  )
  ON CONFLICT (user_id, month_year) DO UPDATE SET
    subscription_id = COALESCE(monthly_usage_summary.subscription_id, NEW.subscription_id),
    self_analysis_count = monthly_usage_summary.self_analysis_count + 
      CASE WHEN NEW.service_type = 'self_analysis' AND NOT NEW.is_reanalysis THEN 1 ELSE 0 END,
    self_reanalysis_count = monthly_usage_summary.self_reanalysis_count + 
      CASE WHEN NEW.service_type = 'self_analysis' AND NEW.is_reanalysis THEN 1 ELSE 0 END,
    other_analysis_count = monthly_usage_summary.other_analysis_count + 
      CASE WHEN NEW.service_type = 'other_analysis' THEN 1 ELSE 0 END,
    relationship_analysis_count = monthly_usage_summary.relationship_analysis_count + 
      CASE WHEN NEW.service_type = 'relationship_analysis' THEN 1 ELSE 0 END,
    coaching_tokens_used = monthly_usage_summary.coaching_tokens_used + 
      CASE WHEN NEW.service_type = 'coaching' THEN NEW.tokens_used ELSE 0 END,
    total_cost_usd = monthly_usage_summary.total_cost_usd + NEW.cost_usd,
    total_charged_usd = monthly_usage_summary.total_charged_usd + NEW.price_charged_usd,
    updated_at = CURRENT_TIMESTAMP;
  
  RETURN NEW;
END;
$$;


--
-- Name: update_subscription_credits(text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_subscription_credits(p_subscription_id text, p_service_type text, p_amount integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_current_credits JSONB;
    v_new_value INTEGER;
BEGIN
    -- Get current credits
    SELECT credits_remaining INTO v_current_credits
    FROM user_subscriptions
    WHERE id = p_subscription_id;
    
    -- Calculate new value
    v_new_value := COALESCE((v_current_credits->p_service_type)::INTEGER, 0) - p_amount;
    
    -- Don't allow negative credits
    IF v_new_value < 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Update credits
    UPDATE user_subscriptions
    SET credits_remaining = jsonb_set(
        COALESCE(credits_remaining, '{}'::jsonb),
        ARRAY[p_service_type],
        to_jsonb(v_new_value)
    ),
    credits_used = jsonb_set(
        COALESCE(credits_used, '{}'::jsonb),
        ARRAY[p_service_type],
        to_jsonb(COALESCE((credits_used->p_service_type)::INTEGER, 0) + p_amount)
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE id = p_subscription_id;
    
    RETURN TRUE;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: analysis_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.analysis_results (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    analysis_type character varying(50) NOT NULL,
    status character varying(20) DEFAULT 'processing'::character varying NOT NULL,
    s0_data jsonb,
    s1_data jsonb,
    result_markdown text,
    lifecoaching_notes jsonb,
    error_message text,
    retry_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone,
    metadata jsonb
);


--
-- Name: TABLE analysis_results; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.analysis_results IS 'Stores all analysis results with status tracking';


--
-- Name: COLUMN analysis_results.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.analysis_results.status IS 'Current status: processing, completed, or error';


--
-- Name: COLUMN analysis_results.s0_data; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.analysis_results.s0_data IS 'S0 form data (stored for retry functionality)';


--
-- Name: COLUMN analysis_results.s1_data; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.analysis_results.s1_data IS 'S1 form data (stored for retry functionality)';


--
-- Name: assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assessments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    person_id uuid NOT NULL,
    type text,
    version text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT assessments_type_check CHECK ((type = ANY (ARRAY['S1'::text, 'S2'::text, 'S3'::text, 'S4'::text])))
);


--
-- Name: chat_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    dyad_id uuid NOT NULL,
    metadata jsonb
);


--
-- Name: dyad_scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dyad_scores (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    dyad_id uuid NOT NULL,
    compatibility_score real,
    strengths_json jsonb,
    risks_json jsonb,
    plan_json jsonb,
    confidence real
);


--
-- Name: dyads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dyads (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    a_person_id uuid NOT NULL,
    b_person_id uuid NOT NULL,
    relation_type text NOT NULL
);


--
-- Name: iap_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.iap_products (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    platform character varying(20) NOT NULL,
    product_id character varying(255) NOT NULL,
    product_type character varying(50) NOT NULL,
    plan_id character varying(50),
    service_type character varying(50),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT iap_products_product_type_check CHECK (((product_type)::text = ANY (ARRAY[('subscription'::character varying)::text, ('consumable'::character varying)::text, ('non_consumable'::character varying)::text])))
);


--
-- Name: iap_purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.iap_purchases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    platform character varying(20) NOT NULL,
    product_id character varying(255) NOT NULL,
    transaction_id character varying(255) NOT NULL,
    receipt_data text,
    validation_status character varying(50) DEFAULT 'pending'::character varying,
    validation_response jsonb,
    created_at timestamp without time zone DEFAULT now(),
    validated_at timestamp without time zone,
    CONSTRAINT iap_purchases_platform_check CHECK (((platform)::text = ANY (ARRAY[('ios'::character varying)::text, ('android'::character varying)::text])))
);


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items (
    id text NOT NULL,
    form text,
    section text,
    subscale text,
    text_tr text,
    type text,
    options_tr text,
    reverse_scored integer DEFAULT 0,
    scoring_key text,
    weight real DEFAULT 1.0,
    notes text,
    display_order integer,
    test_type character varying(50)
);


--
-- Name: language_incidents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.language_incidents (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    report_type text,
    user_language text NOT NULL,
    detected_language text NOT NULL,
    content_preview text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT language_incidents_report_type_check CHECK ((report_type = ANY (ARRAY['self'::text, 'other'::text, 'dyad'::text, 'coach'::text])))
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    session_id uuid NOT NULL,
    role text,
    content text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT messages_role_check CHECK ((role = ANY (ARRAY['user'::text, 'assistant'::text, 'system'::text])))
);


--
-- Name: monthly_usage_summary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.monthly_usage_summary (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    subscription_id uuid,
    month_year text NOT NULL,
    self_analysis_count integer DEFAULT 0,
    self_reanalysis_count integer DEFAULT 0,
    other_analysis_count integer DEFAULT 0,
    relationship_analysis_count integer DEFAULT 0,
    coaching_tokens_used integer DEFAULT 0,
    total_cost_usd numeric(10,4) DEFAULT 0,
    total_charged_usd numeric(10,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: payg_pricing; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payg_pricing (
    id text NOT NULL,
    service_type text NOT NULL,
    price_usd numeric(10,2) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: payg_purchases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payg_purchases (
    id text DEFAULT (gen_random_uuid())::text NOT NULL,
    user_id text NOT NULL,
    service_type text NOT NULL,
    quantity integer DEFAULT 1,
    unit_price numeric(10,2) NOT NULL,
    total_price numeric(10,2) NOT NULL,
    payment_status text DEFAULT 'pending'::text,
    payment_method text,
    transaction_id text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    iap_transaction_id character varying(255)
);


--
-- Name: people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.people (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    label text NOT NULL,
    relation_type text NOT NULL,
    gender text,
    age integer,
    notes text
);


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    owner_user_id uuid NOT NULL,
    dyad_id uuid NOT NULL,
    markdown text,
    version text
);


--
-- Name: responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.responses (
    id bigint NOT NULL,
    assessment_id uuid NOT NULL,
    item_id text NOT NULL,
    value text NOT NULL,
    rt_ms integer
);


--
-- Name: responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.responses_id_seq OWNED BY public.responses.id;


--
-- Name: scores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scores (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    assessment_id uuid NOT NULL,
    bigfive_json jsonb,
    mbti_json jsonb,
    enneagram_json jsonb,
    attachment_json jsonb,
    conflict_json jsonb,
    social_json jsonb,
    quality_flags jsonb
);


--
-- Name: subscription_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscription_plans (
    id text NOT NULL,
    name text NOT NULL,
    self_analysis_limit integer NOT NULL,
    self_reanalysis_limit integer NOT NULL,
    other_analysis_limit integer NOT NULL,
    relationship_analysis_limit integer NOT NULL,
    coaching_tokens_limit integer NOT NULL,
    price_usd numeric(10,2) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: token_costs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.token_costs (
    id text NOT NULL,
    model_name text NOT NULL,
    input_cost_per_1k numeric(10,6) NOT NULL,
    output_cost_per_1k numeric(10,6) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: usage_tracking; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usage_tracking (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    service_type text NOT NULL,
    target_id text,
    is_reanalysis boolean DEFAULT false,
    tokens_used integer DEFAULT 0,
    input_tokens integer DEFAULT 0,
    output_tokens integer DEFAULT 0,
    cost_usd numeric(10,4),
    price_charged_usd numeric(10,2),
    subscription_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: user_lifecoaching_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_lifecoaching_notes (
    user_id uuid NOT NULL,
    notes jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE user_lifecoaching_notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.user_lifecoaching_notes IS 'Stores AI-generated lifecoaching context notes for each user';


--
-- Name: COLUMN user_lifecoaching_notes.notes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.user_lifecoaching_notes.notes IS 'JSON data containing user insights for coaching: values, boundaries, triggers, communication style, etc.';


--
-- Name: user_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_subscriptions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    plan_id text,
    status text DEFAULT 'active'::text,
    billing_cycle text DEFAULT 'monthly'::text,
    start_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    end_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    credits_used jsonb DEFAULT '{}'::jsonb,
    credits_remaining jsonb DEFAULT '{}'::jsonb,
    is_primary boolean DEFAULT false,
    iap_transaction_id character varying(255)
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email text,
    locale text,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: responses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responses ALTER COLUMN id SET DEFAULT nextval('public.responses_id_seq'::regclass);


--
-- Data for Name: analysis_results; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.analysis_results (id, user_id, analysis_type, status, s0_data, s1_data, result_markdown, lifecoaching_notes, error_message, retry_count, created_at, completed_at, metadata) FROM stdin;
1ee06ddc-4e15-4bb1-b2c0-d0fdbb3bd3f9	5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	self	completed	{"S0_AGE": 28, "S0_GENDER": "Erkek", "S0_HOBBIES": "Kitap okuma, yüzme, doğa yürüyüşü", "S0_LIFE_GOAL": "Kendi işimi kurmak ve finansal özgürlüğe ulaşmak", "S0_TOP_CHALLENGES": "İş-yaşam dengesi ve stres yönetimi"}	{"S1_BF_C1": 5, "S1_BF_E1": 2, "S1_BF_O1": 4, "S1_MB_FC1": "B", "S1_OE_HAPPY": "Üniversiteden mezun olduğum gün", "S1_DISC_SJT1": 0, "S1_OE_STRENGTHS": "Analitik düşünme, sorumluluk, hızlı öğrenme"}	Hazır mısınız? Başlayalım..\n\nGerektiğinde keskin olabilirim. Dünyayı okuma biçimim özür dilemeksizin doğrudandır. Amacım sizi daha güçlü ve daha mutlu kılmaktır; bu yüzden zaman zaman sizi sert bir şekilde eleştireceğim - asla sizi küçümsemek için değil, her zaman sizi gerçekliğe demirlemek için.\n\n| Özellik / Boyut | Puan |\n|------------------------------------|-----------------|\n| **MBTI Tipi** | Yetersiz veri |\n| MBTI Dışadönüklük (E) | Yetersiz veri |\n| MBTI İçedönüklük (I) | Yetersiz veri |\n| MBTI Duyumsama (S) | Yetersiz veri |\n| MBTI Sezgi (N) | Yetersiz veri |\n| MBTI Düşünme (T) | Yetersiz veri |\n| MBTI Hissetme (F) | Yetersiz veri |\n| MBTI Yargılama (J) | Yetersiz veri |\n| MBTI Algılama (P) | Yetersiz veri |\n| **Beş Faktör - Deneyime Açıklık (O)** | 75% |\n| **Beş Faktör - Sorumluluk (C)** | 100% |\n| **Beş Faktör - Dışadönüklük (E)** | 25% |\n| **Beş Faktör - Uyumluluk (A)** | Yetersiz veri |\n| **Beş Faktör - Duygusal Denge (N)** | Yetersiz veri |\n| **DISC - Hakimiyet (D)** | Yetersiz veri |\n| **DISC - Etki (I)** | Yetersiz veri |\n| **DISC - Kararlılık (S)** | Yetersiz veri |\n| **DISC - Uyum (C)** | Yetersiz veri |\n| Bağlanma - Kaygı | Yetersiz veri |\n| Bağlanma - Kaçınma | Yetersiz veri |\n| Çatışma Stili (Birincil) | Yetersiz veri |\n| Duygu Düzenleme - Yeniden Değerlendirme | Yetersiz veri |\n| Duygu Düzenleme - Bastırma | Yetersiz veri |\n| Empati - Duygusal İlgi | Yetersiz veri |\n| Empati - Perspektif Alma | Yetersiz veri |\n\n## Temel Kişiliğiniz\n\nAnaliziniz, son derece **disiplinli, hedef odaklı ve içe dönük** bir yapıya işaret ediyor. Kişiliğinizin temel direği, **Sorumluluk (Conscientiousness)** boyutundaki olağanüstü yüksek (%100) puandır. Bu, sizi doğal olarak organize, güvenilir ve görevlerini sonuna kadar takip eden biri yapar. Bir işe başladığınızda, onu en yüksek standartlarda bitirme eğilimindesiniz. Bu, hem en büyük gücünüz hem de en önemli risk alanınızdır.\n\n**Dışadönüklük (Extraversion)** puanınızın (%25) düşük olması, enerjinizi dış dünyadan ve sosyal etkileşimlerden ziyade kendi iç dünyanızdan, düşüncelerinizden ve odaklandığınız projelerden aldığınızı gösteriyor. Bu, sizi kalabalıklar içinde veya sürekli sosyal etkileşim gerektiren ortamlarda hızla yorulan biri yapar. Derinlemesine düşünmeyi, yalnız çalışmayı ve anlamlı, bire bir ilişkileri yüzeysel sosyal bağlara tercih edersiniz.\n\n**Deneyime Açıklık (Openness)** puanınızın (%75) oldukça yüksek olması, bu yapılandırılmış ve içe dönük doğanıza entelektüel bir merak ve esneklik katıyor. Yeni fikirleri, soyut kavramları ve farklı bakış açılarını keşfetmekten hoşlanırsınız. Bu, sizi katı bir uygulayıcı olmaktan çıkarıp, kendi alanınızda yenilikçi ve stratejik düşünebilen birine dönüştürür. Kendi kendinize "Analitik düşünme" ve "hızlı öğrenme" yeteneklerinizi atfetmeniz bu özellikle tamamen uyumludur.\n\nÖzetle, profiliniz, büyük hedeflere ulaşmak için gereken içsel motoru ve disiplini taşıyan, ancak bu hedeflere giden yolda sosyal enerji yönetimi ve mükemmeliyetçilikle mücadele etmesi gereken bir stratejist ve uygulayıcıyı tanımlıyor.\n\n## Güçlü Yönleriniz\n\nVerileriniz, somut ve pratik avantajlar sağlayan birkaç temel gücü ortaya koyuyor. Bunlar, üzerinde kariyer ve kişisel tatmin inşa edebileceğiniz temel taşlarıdır.\n\n*   **Sarsılmaz Sorumluluk ve Güvenilirlik:** %100 Sorumluluk puanınız, sözlerinizin ve taahhütlerinizin sağlam olduğunu gösterir. Bir görev size verildiğinde, o görevin tamamlanacağı ve yüksek kalitede yapılacağı konusunda insanlar size güvenir. Bu, profesyonel ortamlarda sizi paha biçilmez kılar ve uzun vadeli projelerde başarı için kritik bir temel oluşturur. Kendi işinizi kurma hedefinizde, bu özellik iş ahlakınızın ve marka itibarınızın temelini oluşturacaktır.\n\n*   **Derin Odaklanma ve Bağımsız Çalışma Yeteneği:** Düşük dışadönüklük, dikkatinizin dağılmasını önleyen bir kalkan görevi görür. Dış uyaranlara daha az ihtiyaç duyduğunuz için, karmaşık sorunları çözmek veya uzun saatler boyunca konsantrasyon gerektiren işleri tamamlamak için derinlemesine odaklanabilirsiniz. Bu, özellikle strateji geliştirme, kodlama, yazma veya herhangi bir analitik çalışma için muazzam bir avantajdır.\n\n*   **Analitik ve Stratejik Zeka:** Yüksek Deneyime Açıklık, sizi sadece görevleri yerine getiren biri yapmaz; aynı zamanda "neden" ve "nasıl daha iyi olabilir" sorularını soran biri yapar. Kalıpları görme, verileri analiz etme ve gelecekteki olasılıkları planlama yeteneğiniz güçlüdür. Kendi belirttiğiniz "analitik düşünme" gücü, bu özelliğin bir yansımasıdır ve iş kurma hedefinizde pazar analizi ve stratejik planlama gibi alanlarda size üstünlük sağlayacaktır.\n\n*   **Hızlı Öğrenme ve Zihinsel Esneklik:** Yeni fikirlere açık olmanız, yeni becerileri hızla edinmenizi sağlar. Statükoya meydan okumaktan ve daha verimli yollar aramaktan çekinmezsiniz. Bu, özellikle hızla değişen bir sektörde kendi işinizi kurarken kritik bir hayatta kalma becerisidir. Bir soruna takılıp kalmak yerine, yeni yaklaşımlar öğrenip adapte olabilirsiniz.\n\n## Kör Noktalar ve Riskler\n\nGüçlü yönlerinizin kaçınılmaz birer gölgesi vardır. Bu riskleri anlamak, onları yönetmenin ilk adımıdır. Bunları görmezden gelmek, eninde sonunda hedeflerinize ulaşmanızı engelleyecektir.\n\n*   **Mükemmeliyetçilik ve Tükenmişlik Sendromu:** %100 Sorumluluk, "yeterince iyi" kavramını kabul etmeyi zorlaştırır. Bu durum, sizi sürekli daha fazlasını yapmaya, detaylarda boğulmaya ve dinlenmeyi bir lüks olarak görmeye itebilir. Kendi belirttiğiniz "iş-yaşam dengesi ve stres yönetimi" zorluğu doğrudan bu kör noktadan kaynaklanmaktadır. Bu yolda devam ederseniz, tükenmişlik sadece bir risk değil, neredeyse matematiksel bir kesinliktir.\n\n*   **Sosyal Geri Çekilme ve Ağ Kurmada Zorluk:** İçe dönük yapınız, özellikle kendi işinizi kurma gibi dışa dönük eylemler gerektiren bir hedefle birleştiğinde bir engele dönüşebilir. Potansiyel müşterilerle, yatırımcılarla veya ortaklarla ilişki kurmak için gereken sosyal enerjiye sahip olmayabilirsiniz. Bu, dünyanın en iyi ürününü veya hizmetini yaratsanız bile, kimsenin bundan haberi olmaması riskini doğurur.\n\n*   **Eleştiriye Aşırı Duyarlılık ve Savunmacılık:** Yaptığınız işe bu kadar yüksek standartlar ve kişisel yatırım koyduğunuzda, eleştiriyi kişisel bir saldırı olarak algılama eğiliminiz olabilir. Mükemmeliyetçiliğiniz, herhangi bir hatanın veya olumsuz geri bildirimin benlik saygınıza bir darbe gibi gelmesine neden olabilir. Bu, öğrenme ve büyüme için gerekli olan yapıcı geri bildirimleri kabul etmenizi zorlaştırabilir.\n\n*   **Delegasyon Yapamama:** "En iyisini ben yaparım" düşüncesi, yüksek Sorumluluk sahibi kişilerin yaygın bir tuzağıdır. Başkalarına görev vermekte zorlanabilir, her detayı kontrol etme ihtiyacı hissedebilirsiniz. Kendi işinizi kurarken bu, büyümenizin önündeki en büyük engel olacaktır. Tek başınıza her şeyi yapmaya çalışmak, sizi darboğaza sokar ve işinizin ölçeklenmesini imkansız hale getirir.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişkilerde, muhtemelen **güvenilir, sadık ve istikrarlı** bir partner olarak algılanıyorsunuz. Sözlerinizi tutar, sorumluluklarınızı yerine getirirsiniz. Ancak, içe dönük doğanız, duygusal ihtiyaçlarınızı veya düşüncelerinizi sözlü olarak sık sık ifade etmediğiniz anlamına gelebilir. Partneriniz, sizin sevginizi ve bağlılığınızı eylemlerinizden (sorumluluklarınızı yerine getirme, destek olma) anlamak zorundadır, çünkü bunu sık sık duymayabilir.\n\nBu durum, daha dışa dönük veya duygusal olarak ifadeci bir partnere sahipseniz çatışmaya yol açabilir. Onlar daha fazla sözlü teyit, sosyal aktivite ve spontanlık beklerken, siz huzuru ve sessizliği tercih edebilirsiniz. Sizin için "kaliteli zaman", birlikte sessizce bir aktivite yapmak olabilirken, partneriniz için bu, derin bir sohbet veya sosyal bir etkinliğe katılmak anlamına gelebilir.\n\nArkadaşlıklarınız muhtemelen az sayıda ama derindir. Yüzeysel sohbetlerden ve büyük gruplardan kaçınır, entelektüel veya ortak ilgi alanlarına dayalı güçlü bağlar kurarsınız. Arkadaşlarınız, zor zamanlarda güvenebilecekleri, mantıklı tavsiyeler veren biri olduğunuzu bilirler. Ancak, sosyal etkinlikleri başlatan veya grubu bir araya getiren kişi olma olasılığınız düşüktür.\n\n## Kariyer ve Çalışma Tarzı\n\nKariyer yolunuzda, "Kendi işimi kurmak ve finansal özgürlüğe ulaşmak" hedefi, kişiliğinizle hem mükemmel bir uyum hem de ciddi bir çelişki içindedir.\n\n**Uyumlu Yönler:** Yüksek Sorumluluk, bir iş kurmak için gereken özveri, disiplin ve uzun saatler çalışma yeteneğini size doğal olarak verir. Planlama, organize etme ve bir vizyonu somut adımlara dökme konusunda mükemmelsiniz. Yüksek Deneyime Açıklık, pazarınızdaki yenilikleri takip etmenizi ve stratejik olarak uyum sağlamanızı sağlar. Bağımsız çalışma yeteneğiniz, işin ilk aşamalarında tek başınıza ilerlemenizi kolaylaştırır.\n\n**Çelişkili Yönler:** Girişimcilik, acımasız bir şekilde sosyal bir faaliyettir. Satış yapmanız, pazarlık etmeniz, ağ kurmanız, ekibinizi motive etmeniz ve vizyonunuzu başkalarına satmanız gerekir. Düşük Dışadönüklük, bu alanların her birini sizin için doğal olmayan ve enerji tüketen faaliyetlere dönüştürür. En büyük zorluğunuz ürün veya hizmeti geliştirmek değil, onu dünyaya duyurmak ve satmak olacaktır.\n\nBu çelişkiyi yönetmek için iki yol vardır: Ya bu becerileri bilinçli bir şekilde geliştirmek için kendinizi zorlarsınız (ki bu yorucu olacaktır) ya da bu alanlarda güçlü olan bir ortak bulursunuz. Sizin teknik ve stratejik beyninizle, dışa dönük bir ortağın sosyal ve satış becerilerini birleştirmek, başarı şansınızı katlayacaktır.\n\n## Duygusal Desenler ve Stres\n\nStresle başa çıkma yönteminiz, muhtemelen içselleştirme ve problem çözme odaklıdır. Bir sorunla karşılaştığınızda, duygusal bir patlama yaşamak yerine, sorunu analiz etmeye ve mantıklı bir çözüm bulmaya çalışırsınız. Bu genellikle etkilidir, ancak çözülemeyen veya kontrolünüz dışındaki sorunlarla karşılaştığınızda, bu içselleştirme süreci ruminasyona (aynı olumsuz düşünceleri tekrar tekrar zihinde evirip çevirme) dönüşebilir.\n\nStresinizin ana kaynağı, kendi kendinize koyduğunuz yüksek standartlardır. Bir hedefe ulaşamadığınızda veya bir hata yaptığınızda, en sert eleştirmeniniz kendiniz olursunuz. Bu, benlik saygınızı doğrudan başarı ve üretkenliğe bağlama riskini taşır. Başarısızlık, sadece bir sonuç değil, kişisel bir kusur gibi hissedilebilir.\n\nBelirttiğiniz "stres yönetimi" zorluğu, bu içsel baskı mekanizmasının bir sonucudur. Fiziksel aktiviteler (yüzme, doğa yürüyüşü gibi hobileriniz) bu birikmiş stresi atmak için mükemmel kanallardır, çünkü sizi zihninizden çıkarıp bedeninize odaklanmaya zorlarlar. Bu aktiviteleri bir lüks olarak değil, zihinsel sağlığınız için bir zorunluluk olarak görmelisiniz.\n\n## Yaşam Desenleri ve Muhtemel Tuzaklar\n\nMevcut profilinizle, hayatınız boyunca muhtemelen istikrarlı ve ölçülebilir başarılar elde etme eğiliminde olacaksınız. Kariyerinizde adım adım yükselecek, hedeflerinize metodik bir şekilde ulaşacaksınız. Ancak dikkat etmeniz gereken birkaç muhtemel tuzak var:\n\n*   **"Ne Zaman Yeterli Olacak?" Tuzağı:** Yüksek Sorumluluk, hedeflere ulaştığınızda bile tatmin olmayı zorlaştırabilir. Bir zirveye ulaştığınızda, kutlamak yerine hemen bir sonraki daha yüksek zirveyi gözünüze kestirebilirsiniz. Bu, sürekli bir koşu bandında olma hissine yol açar ve "finansal özgürlüğe" ulaşsanız bile, zihinsel olarak asla "özgür" hissetmemenize neden olabilir.\n\n*   **İlişkileri İhmal Etme Riski:** İşinize ve hedeflerinize o kadar odaklanabilirsiniz ki, kişisel ilişkilerinizin gerektirdiği zamanı ve enerjiyi ayırmayı unutabilirsiniz. İlişkiler, bir proje gibi yönetilemez; sürekli bakım ve duygusal yatırım gerektirirler. Bu dengeyi kuramazsanız, profesyonel olarak başarılı ama kişisel olarak yalnız kalma riskiyle karşı karşıya kalırsınız.\n\n*   **Spontanlığı ve Oyunu Kaybetme:** Hayatınız aşırı planlı ve yapılandırılmış hale gelebilir. Plansız bir gün geçirme, sadece anın tadını çıkarma veya "üretken olmayan" bir hobiyle uğraşma fikri size rahatsız edici gelebilir. Bu, hayatın neşesini ve yaratıcılığını besleyen spontan anları kaçırmanıza neden olur.\n\n## Uygulanabilir İleriye Dönük Yol\n\nAşağıdakiler, potansiyelinizi en üst düzeye çıkarırken risklerinizi yönetmenize yardımcı olacak somut, davranışsal adımlardır.\n\n*   **"Yeterince İyi" Prensibini Benimseyin:** Her görev için kendinize sorun: "Bu işin %80'lik kalitede tamamlanması yeterli mi?" Çoğu zaman cevap evet olacaktır. Mükemmeliyetçiliği, yalnızca gerçekten önemli olan %20'lik görevlere saklayın. Bu, enerjinizi korumanıza ve tükenmişliği önlemenize yardımcı olacaktır.\n\n*   **Takviminize "Hiçbir Şey Yapmama" Zamanı Ekleyin:** Tıpkı bir iş toplantısı gibi, takviminize haftada en az iki saatlik "boş zaman" blokları ekleyin. Bu süre zarfında işle ilgili hiçbir şey düşünmek, plan yapmak veya üretmek yasaktır. Bu, dinlenmenin pazarlık edilemez bir öncelik olduğunu beyninize öğretmenize yardımcı olacaktır.\n\n*   **Yapılandırılmış Sosyalleşme Planı Oluşturun:** Sosyalleşme enerjinizi tükettiği için, onu bir görev gibi ele alın. Ayda bir veya iki tane, sizin için önemli olan ağ kurma etkinliği veya sosyal buluşma belirleyin. Bu etkinliklere hazırlıklı gidin (kiminle konuşmak istediğiniz gibi) ve enerji seviyeniz düştüğünde ayrılmak için kendinize izin verin.\n\n*   **Tamamlayıcı Bir Ortak Arayın:** Kendi işinizi kurma hedefinizde ciddiyken, aktif olarak sizin zayıf yönlerinizi tamamlayan bir ortak arayın. Siz ürün, strateji ve operasyonlara odaklanırken, satış, pazarlama ve insan ilişkilerinde güçlü, dışa dönük birini bulun. Bu, başarı şansınızı logaritmik olarak artırır.\n\n*   **Fiziksel Sınırlar Koyun:** İş gününüzün ne zaman başlayıp ne zaman bittiğine dair net kurallar belirleyin. Akşam saat 8'den sonra iş e-postalarını kontrol etmemek veya hafta sonları bir tam günü tamamen işten uzak geçirmek gibi. Fiziksel olarak işten ayrılmak, zihinsel olarak da ayrılmanıza yardımcı olur.\n\n*   **"Başarısızlık Özgeçmişi" Tutun:** Bir kağıda veya dosyaya, geçmişte yaşadığınız başarısızlıkları, hataları ve yanlış adımları yazın. Her birinin yanına, o deneyimden ne öğrendiğinizi ve o başarısızlığa rağmen nasıl hayatta kaldığınızı not edin. Bu, başarısızlığın son değil, bir veri noktası olduğunu anlamanıza yardımcı olur.\n\n*   **Delegasyon Alıştırması Yapın:** Küçük, düşük riskli görevlerle başlayarak başkalarına iş vermeye başlayın. Örneğin, bir sanal asistana randevularınızı düzenletmek gibi. Görevin mükemmel yapılmasa bile dünyanın sonunun gelmediğini görmek, daha büyük sorumlulukları devretme konusunda size güven verecektir.\n\n*   **Geri Bildirimi Kişiselleştirmeyin:** Birisi işinizle ilgili eleştiride bulunduğunda, bunu bir veri olarak kabul etme pratiği yapın. "Bu geri bildirimde işime yarayacak bir doğruluk payı var mı?" diye sorun. Cevap evet ise, kullanın. Hayır ise, atın. Geri bildirimi karakterinize bir saldırı olarak değil, projenize bir hediye olarak görmeye çalışın.\n\n## Kendi Sözlerinizden: Anılar ve Anlam\n\nKendi ifadeleriniz, test sonuçlarının ortaya koyduğu tabloyu doğruluyor ve ona derinlik katıyor. Bu kelimeler, sizin motivasyonlarınızın ve zorluklarınızın ham halidir.\n\nEn mutlu anınız olarak **"Üniversiteden mezun olduğum gün"** demeniz son derece anlamlıdır. Bu, sosyal bir olay, bir ilişki anı veya spontane bir macera değil; uzun vadeli, zorlu bir hedefin başarıyla tamamlanmasıdır. Bu, ödül sisteminizin **başarı ve tamamlanma** üzerine kurulu olduğunu gösteriyor. Sizi en çok neyin motive ettiğini anlamak için bundan daha net bir kanıt olamaz: zor bir işi alıp sonuca ulaştırmak.\n\nHayattaki ana hedefiniz **"Kendi işimi kurmak ve finansal özgürlüğe ulaşmak"**. Bu, mezuniyet anınızdaki tatmin duygusunu hayatınızın tamamına yayma arzusudur. Bu sadece para kazanmakla ilgili bir hedef değil; kontrol, özerklik ve kendi standartlarınıza göre bir şeyler inşa etme arzusudur. Bu, yüksek Sorumluluk özelliğinizin doğal bir uzantısıdır.\n\nEn büyük zorluğunuz olarak **"İş-yaşam dengesi ve stres yönetimi"**ni belirtmeniz, bu hedefe giden yoldaki en büyük engeli gördüğünüzü gösteriyor. Bu, içgörünüzün yüksek olduğunu kanıtlar. Motorunuzun ne kadar güçlü olduğunu biliyorsunuz, ama aynı zamanda bu motorun aşırı ısınma riskini de hissediyorsunuz.\n\nKendinizde gördüğünüz güçlü yönler - **"Analitik düşünme, sorumluluk, hızlı öğrenme"** - kişilik analiziyle bire bir örtüşüyor. Bu, kendinizi oldukça doğru bir şekilde tanıdığınızı gösterir. Sorun öz-farkındalık eksikliği değil, bu bilgiyi davranışa dökme ve kör noktaları yönetme konusundaki strateji eksikliğidir. Bu rapor, tam olarak bu stratejiyi sağlamayı amaçlamaktadır.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, psikolojide onlarca yıldır geçerliliği kanıtlanmış bilimsel modellere dayanmaktadır. Vardığımız sonuçlar, keyfi yorumlar değil, kişilik bilimi alanındaki sağlam araştırmaların bir sentezidir.\n\nTemel çerçevemiz, **Beş Faktör Kişilik Modeli**'dir (genellikle OCEAN olarak bilinir). Bu model, kişiliği beş geniş boyutta (Deneyime Açıklık, Sorumluluk, Dışadönüklük, Uyumluluk, Duygusal Denge) ele alır. Araştırmalar, bu özelliklerin iş performansı, ilişki tatmini, zihinsel sağlık ve hatta yaşam süresi gibi çok çeşitli yaşam sonuçlarını öngörebildiğini tutarlı bir şekilde göstermiştir. Sizin durumunuzda, özellikle yüksek Sorumluluk puanınız, akademik ve profesyonel başarı için güçlü bir öngörücüdür, ancak aynı zamanda mükemmeliyetçilik ve tükenmişlik riskini de beraberinde getirir. Düşük Dışadönüklük puanınız ise analitik rollerde başarıyı öngörürken, satış veya halkla ilişkiler gibi sosyal olarak yoğun rollerde zorluk yaşayabileceğinize işaret eder.\n\n**MBTI** ve **DISC** gibi diğer modeller, davranışsal tercihleri ve stilleri anlamak için faydalı çerçeveler sunar. MBTI, bilgi işleme ve karar verme şeklinize odaklanırken (örneğin, mantık mı yoksa değerler mi öncelikli), DISC daha çok gözlemlenebilir davranışsal eğilimlerinizi (örneğin, bir ekip içinde ne kadar iddialı veya destekleyici olduğunuz) tanımlar. Yanıtlarınız bu testlerin skorlarını hesaplamak için yeterli veri sağlamadığından, bu analizde bu modellere dayalı çıkarımlar yapmaktan kaçındık. Bu, varsayımlarda bulunmak yerine yalnızca eldeki somut kanıtlara bağlı kalma taahhüdümüzün bir parçasıdır.\n\nBu analizde sunulan öngörüler ve tavsiyeler, sizin gibi kişilik profillerine sahip bireylerin yaşam yollarında tekrar tekrar gözlemlenen kalıplara dayanmaktadır. Ancak unutmayın ki, kişilik bir kader değil, bir eğilimdir. Bu eğilimleri anlamak, size kendi yolunuzu daha bilinçli bir şekilde çizme, güçlü yönlerinizi en üst düzeye çıkarma ve risklerinizi proaktif olarak yönetme gücü verir.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilendirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-20 22:59:23.030584+03	2025-08-20 23:00:49.646929+03	{"language": "tr", "language_ok": true}
86d89883-2a2a-44e0-92db-78130b1da05d	5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	self	completed	{"S0_AGE": 28, "S0_GENDER": "Erkek", "S0_HOBBIES": "Kitap okuma, yüzme, doğa yürüyüşü", "S0_LIFE_GOAL": "Kendi işimi kurmak ve finansal özgürlüğe ulaşmak", "S0_TOP_CHALLENGES": "İş-yaşam dengesi ve stres yönetimi"}	{"S1_BF_C1": 5, "S1_BF_E1": 2, "S1_BF_O1": 4, "S1_MB_FC1": "B", "S1_OE_HAPPY": "Üniversiteden mezun olduğum gün", "S1_DISC_SJT1": 0, "S1_OE_STRENGTHS": "Analitik düşünme, sorumluluk, hızlı öğrenme"}	Hazır mısınız? Başlayalım..\n\nGerektiğinde sivri dilli olabilirim. Dünyayı okuma biçimim, özür dilemeyen bir netlik taşır. Amacım sizi daha güçlü ve mutlu kılmaktır; bu nedenle zaman zaman sizi sert bir şekilde eleştireceğim. Bunu sizi küçümsemek için değil, daima gerçeğe demirlemek için yapacağım.\n\n| Özellik / Boyut | Puan |\n|-------------------|-------|\n| **MBTI Tipi** | Yetersiz Veri |\n| MBTI Dışadönüklük (E) | 25% |\n| MBTI İçedönüklük (I) | 75% |\n| MBTI Duyumsama (S) | Yetersiz Veri |\n| MBTI Sezgi (N) | Yetersiz Veri |\n| MBTI Düşünme (T) | Yetersiz Veri |\n| MBTI Hissetme (F) | Yetersiz Veri |\n| MBTI Yargılama (J) | Yetersiz Veri |\n| MBTI Algılama (P) | Yetersiz Veri |\n| **Big Five - Deneyime Açıklık (O)** | 75% |\n| **Big Five - Sorumluluk (C)** | 100% |\n| **Big Five - Dışadönüklük (E)** | 25% |\n| **Big Five - Uyumluluk (A)** | Yetersiz Veri |\n| **Big Five - Duygusal Denge (N)** | Yetersiz Veri |\n| **DISC - Hakimiyet (D)** | Yetersiz Veri |\n| **DISC - Etkileme (I)** | Yetersiz Veri |\n| **DISC - Sadakat (S)** | Yetersiz Veri |\n| **DISC - Uygunluk (C)** | Yetersiz Veri |\n| Bağlanma - Kaygı | Yetersiz Veri |\n| Bağlanma - Kaçınma | Yetersiz Veri |\n| Çatışma Stili (Birincil) | Yetersiz Veri |\n| Duygu Düzenleme - Yeniden Değerlendirme | Yetersiz Veri |\n| Duygu Düzenleme - Bastırma | Yetersiz Veri |\n| Empati - Duygusal İlgi | Yetersiz Veri |\n| Empati - Perspektif Alma | Yetersiz Veri |\n\n**Önemli Not:** Bu analiz, verdiğiniz sınırlı yanıtlara dayanmaktadır. Özellikle kişilik testlerinin birçok boyutu için veri sağlanmamıştır. Bu nedenle, sonuçlar kişiliğinizin yalnızca belirli yönlerine dair bir ilk bakış sunar ve kapsamlı bir profil olarak görülmemelidir. Analiz, mevcut verileri kendi ifadelerinizle birleştirerek en anlamlı içgörüleri sunmaya odaklanacaktır.\n\n## Temel Kişilik Yapınız\n\nVerileriniz, son derece **sorumlu, disiplinli ve hedef odaklı** bir birey olduğunuzu gösteriyor. Sorumluluk (Conscientiousness) puanınızın en üst düzeyde olması, başladığınız işi bitirme, detaylara dikkat etme ve güvenilirlik gibi özelliklerin karakterinizin temelini oluşturduğuna işaret ediyor. Bu özellik, "kendi işimi kurma" hedefinizle mükemmel bir uyum içindedir. Başarıyı şansa bırakmayan, sistemli ve planlı hareket eden bir yapıdasınız.\n\nBununla birlikte, belirgin bir **içedönüklük** eğiliminiz var. Enerjinizi kalabalık sosyal ortamlardan ziyade yalnız kalarak veya küçük, anlamlı gruplar içinde yeniliyorsunuz. Bu, yüzeysel olmadığınız, aksine derinlemesine düşünmeye ve odaklanmaya ihtiyaç duyduğunuz anlamına gelir. Düşük dışadönüklük, sizi daha gözlemci, dikkatli ve bağımsız bir düşünür yapar. Kendi başınıza çalışmaktan ve problem çözmekten keyif alırsınız.\n\n**Deneyime açıklık** puanınızın yüksek olması, bu disiplinli ve içedönük yapıya önemli bir esneklik katıyor. Yeni fikirlere, farklı bakış açılarına ve entelektüel meraklara açıksınız. Bu, rutinlere sıkışıp kalmanızı engeller ve özellikle girişimcilik gibi belirsizlik ve yenilik gerektiren alanlarda size avantaj sağlar. Analitik düşünme ve hızlı öğrenme yetenekleriniz bu özelliğinizden beslenir. Özetle profiliniz, bir hedefe kilitlendiğinde onu metodik bir şekilde inşa edebilen, ancak bunu yaparken yaratıcılığını ve stratejik düşünme yeteneğini de kullanabilen bir "mimar" veya "stratejist" arketipine benziyor.\n\n## Güçlü Yönleriniz\n\n*   **Sarsılmaz Sorumluluk ve Disiplin:** Sorumluluk puanınızın %100 olması, bunun sadece bir özellik değil, bir yaşam biçimi olduğunu gösteriyor. Size bir görev verildiğinde, en iyi şekilde tamamlanacağından emin olunabilir. Bu, iş hayatında güvenilirlik ve başarı için en temel yapı taşıdır. Kendi işinizi kurma hedefinizde, bu özellik en büyük sermayeniz olacaktır.\n\n*   **Analitik ve Stratejik Düşünme:** Kendi belirttiğiniz "analitik düşünme" gücü, deneyime açıklık özelliğinizle birleşiyor. Karmaşık sorunları bileşenlerine ayırabilir, verileri değerlendirebilir ve mantıksal sonuçlara varabilirsiniz. Bu, duygusal tepkilerle değil, kanıta dayalı kararlar almanızı sağlar.\n\n*   **Bağımsız Çalışma ve Odaklanma Yeteneği:** İçedönük yapınız, dikkatinizin dağıldığı ortamlarda performansınızın düşmesine neden olabilir, ancak size derinlemesine odaklanma ve karmaşık projeler üzerinde saatlerce tek başınıza çalışma yeteneği kazandırır. Bu, özellikle bir iş kurmanın ilk aşamalarındaki yoğun ve bireysel çaba gerektiren dönemler için kritik bir avantajdır.\n\n*   **Hızlı Öğrenme ve Zihinsel Esneklik:** Yeni fikirlere açık olmanız, "hızlı öğrenme" yeteneğinizin temelini oluşturur. Değişen pazar koşullarına, yeni teknolojilere veya beklenmedik zorluklara adapte olma kapasiteniz yüksektir. Statik düşünmezsiniz; aksine, daha iyi bir yol bulduğunuzda mevcut planınızı revize etmekten çekinmezsiniz.\n\n## Kör Noktalar ve Riskler\n\n*   **Tükenmişlik ve İş-Yaşam Dengesizliği Riski:** En büyük gücünüz olan yüksek sorumluluk, aynı zamanda en büyük riskinizi oluşturur. Mükemmeliyetçiliğe ve aşırı çalışmaya olan eğiliminiz, "iş-yaşam dengesi ve stres yönetimi" sorununu doğrudan besler. "Yeterli" olanı kabul etmekte zorlanabilir, dinlenme ve sosyal hayatı işin gerisine atabilirsiniz. Bu, uzun vadede hem fiziksel hem de zihinsel sağlığınızı ciddi şekilde tehdit eden bir tükenmişlik sendromuna yol açabilir.\n\n*   **Sosyal İzolasyon ve Ağ Oluşturma Zorlukları:** İçedönük yapınız, özellikle iş kurma sürecinde kritik olan ağ oluşturma (networking), pazarlama ve satış gibi dışadönüklük gerektiren görevlerde sizi zorlayabilir. Enerjinizi sosyal etkileşimlerden ziyade yalnız çalışarak topladığınız için, gerekli bağlantıları kurmaktan kaçınma veya bu tür etkinlikleri aşırı yorucu bulma eğiliminde olabilirsiniz. Bu, işinizin büyümesini yavaşlatabilir.\n\n*   **Aşırı Analiz (Analysis Paralysis):** Analitik düşünme gücünüz, bazen bir zayıflığa dönüşebilir. Karar vermeden önce tüm verileri toplama ve her olasılığı değerlendirme arzunuz, sizi eyleme geçmekten alıkoyabilir. Özellikle girişimcilikte hızlı karar almanın gerektiği anlarda, bu "analiz felci" durumu değerli fırsatları kaçırmanıza neden olabilir.\n\n*   **Yardım İstemede Güçlük:** Sorumluluk duygunuz ve bağımsız çalışma eğiliminiz, başkalarından yardım istemeyi veya görevleri delege etmeyi zorlaştırabilir. Her şeyi kendiniz kontrol etme ve yapma isteği, iş yükünüzü sürdürülemez bir seviyeye çıkarabilir ve ekibinizin veya ortaklarınızın potansiyelinden tam olarak yararlanmanızı engelleyebilir.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişkilerinizde muhtemelen derinlik ve anlam arayan birisiniz. Yüzeysel sohbetler veya büyük, gürültülü sosyal gruplar size çekici gelmez. Bunun yerine, birkaç yakın dostunuzla entelektüel veya anlamlı konular üzerine konuşmayı tercih edersiniz. Güvenilir ve sadık bir dost olmanız muhtemeldir; söz verdiğinizde tutarsınız ve sevdiklerinize karşı sorumluluklarınızı ciddiye alırsınız.\n\nAncak içedönük yapınız, yeni insanlarla tanışırken ilk adımı atmakta veya duygularınızı anında ifade etmekte zorlanmanıza neden olabilir. Dışarıdan mesafeli veya soğuk görünebilirsiniz, oysa bu sadece sizin düşüncelerinizi ve gözlemlerinizi işlemeniz için zamana ihtiyaç duymanızdan kaynaklanır. Partneriniz veya yakın arkadaşlarınız, sizinle iletişim kurmak için sabırlı olmalı ve size kişisel alan tanımalıdır.\n\nPotansiyel bir çatışma noktası, aşırı çalışma eğiliminizdir. Sevdiklerinize yeterli zaman ve enerji ayıramadığınızda, ilişkilerinizde ihmal edilmişlik hissi yaratabilirsiniz. İş-yaşam dengesi kurma mücadeleniz, sadece sizin kişisel sağlığınız için değil, aynı zamanda ilişkilerinizin sağlığı için de kritiktir.\n\n## Kariyer ve Çalışma Tarzı\n\nKariyer yolunuz, bağımsızlık, uzmanlık ve anlamlı bir sonuç üretme üzerine kuruludur. Analitik, planlama gerektiren ve somut sonuçlar doğuran rollerde parlarsınız. Mühendislik, yazılım geliştirme, finansal analiz, strateji danışmanlığı veya kendi işinizi kurmak gibi alanlar sizin için doğal bir uyum gösterir.\n\n**Çalışma Ortamı:** Açık ofisler gibi sürekli kesintiye uğradığınız, gürültülü ortamlar verimliliğinizi düşürür. Odaklanabileceğiniz, kendi başınıza kalabileceğiniz veya küçük, görev odaklı ekiplerle çalışabileceğiniz yapıları tercih edersiniz. Yönetici olarak, muhtemelen adil, mantıklı ve beklentileri net olan bir lider olursunuz. Ancak ekibinizin sosyal ve duygusal ihtiyaçlarını gözden kaçırma riskiniz vardır.\n\n**Karar Verme:** Kararlarınız veri odaklı ve mantıksaldır. İçgüdüsel veya duygusal kararlardan kaçınırsınız. Bu, finansal ve stratejik konularda büyük bir güçtür. Ancak, insan faktörünün veya pazarın irrasyonel dinamiklerinin önemli olduğu durumlarda, bu katı mantıksal yaklaşımınız kör noktalar yaratabilir.\n\n**Girişimcilik Hedefi:** "Kendi işimi kurmak" hedefiniz, kişilik yapınızla hem uyumlu hem de çelişkilidir. Uyumlu yönü, disiplininiz, sorumluluk duygunuz ve bağımsız çalışma yeteneğinizdir. Bir iş planı hazırlama, ürünü geliştirme ve operasyonları yönetme konusunda mükemmel olabilirsiniz. Çelişkili yönü ise, satış, pazarlama, yatırımcı sunumları ve ekip yönetimi gibi yoğun insan etkileşimi gerektiren alanlardır. Başarılı olmak için ya bu alanlarda kendinizi bilinçli olarak geliştirmeniz ya da bu yönlerinizi tamamlayacak dışadönük bir ortak bulmanız gerekecektir.\n\n## Duygusal Desenler ve Stres\n\nStresle başa çıkma yönteminiz muhtemelen içsel ve bilişseldir. Sorunları kendi başınıza çözmeye, durumu analiz etmeye ve mantıklı bir çıkış yolu bulmaya çalışırsınız. "İş-yaşam dengesi ve stres yönetimi" en büyük zorluğunuz olarak belirttiğinize göre, mevcut stratejileriniz yetersiz kalıyor.\n\nYüksek sorumluluk duygunuz, başarısızlık veya hata yapma durumlarında kendinizi sert bir şekilde eleştirmenize neden olabilir. Stres, sizde muhtemelen anksiyete, endişe ve zihinsel yorgunluk olarak ortaya çıkar. Duygularınızı dışa vurmak yerine içinize atma eğiliminiz olabilir. Bu, zamanla birikerek daha büyük patlamalara veya kronik strese yol açabilir.\n\nHobileriniz olan **kitap okuma, yüzme ve doğa yürüyüşü**, içedönük yapınız için mükemmel deşarj mekanizmalarıdır. Bu aktiviteler size zihinsel olarak dinlenmeniz ve enerjinizi yeniden toplamanız için gereken yalnızlığı ve sakinliği sağlar. Stres yönetimi için bu aktivitelere bilinçli olarak zaman ayırmanız hayati önem taşımaktadır.\n\n## Yaşam Desenleri ve Muhtemel Tuzaklar\n\nSizin gibi bir profil, genellikle hayatının erken dönemlerinde akademik veya profesyonel başarıya ulaşır. Disiplininiz ve zekanız sizi ileri taşır. Ancak 20'li yaşların sonu ve 30'lu yaşlar, kariyer başarısının tek başına yeterli olmadığı, sosyal bağların, kişisel tatminin ve sağlığın da önemli olduğunun fark edildiği bir dönemdir.\n\n**Muhtemel Tuzak:** En büyük tuzak, "başarı tuzağı"dır. Hedeflerinize ulaştıkça (örneğin, finansal özgürlük), bu başarıların sizi beklediğiniz kadar mutlu etmediğini fark edebilirsiniz. Çünkü bu süreçte sosyal ilişkilerinizi, sağlığınızı ve anlık keyifleri feda etmiş olabilirsiniz. En mutlu anınızın bir hedefe ulaştığınız "üniversiteden mezun olduğum gün" olması, mutluluğu bir varış noktası olarak gördüğünüzü gösteriyor. Bu, sürekli bir sonraki hedefe koşarken şimdiki anı kaçırma riskini beraberinde getirir.\n\n**Fırsat:** En büyük fırsatınız, disiplininizi ve stratejik zekanızı sadece işinize değil, hayatınızın tamamına uygulamaktır. İş-yaşam dengesini bir görev, sağlığınızı bir proje, ilişkilerinizi ise bilinçli yatırım gerektiren bir alan olarak görebilirsiniz. Planlama yeteneğinizi kullanarak dinlenme, sosyalleşme ve hobiler için takviminizde "müzakere edilemez" zaman dilimleri yaratabilirsiniz.\n\n## Eyleme Geçirilebilir İleriye Dönük Yol Haritası\n\n1.  **"Yeterince İyi" Prensibini Benimseyin:** Mükemmeliyetçiliğinizin sizi tüketmesine izin vermeyin. Her görevde %100'ü hedeflemek yerine, Pareto Prensibini (%80 sonuç %20 çabadan gelir) uygulayın. Hangi görevlerin %100 çaba gerektirdiğini, hangilerinin %80 ile "yeterince iyi" olacağını bilinçli olarak belirleyin. Bu, enerjinizi korumanıza yardımcı olacaktır.\n\n2.  **Takviminize "Hiçbir Şey Yapmama" Zamanı Ekleyin:** Tıpkı önemli bir iş toplantısı gibi, dinlenme ve toparlanma zamanlarınızı da takviminize birer randevu olarak işleyin. Bu zaman dilimlerinde işle ilgili hiçbir şey düşünmemeye veya yapmamaya kendinizi zorlayın. Doğa yürüyüşü veya yüzme gibi hobileriniz bu zamanlar için mükemmeldir.\n\n3.  **Sınırları Belirleyin ve Savunun:** İş gününüzün ne zaman başlayıp ne zaman bittiğini net bir şekilde tanımlayın. Akşamları ve hafta sonları iş e-postalarını kontrol etmeme kuralı koyun. Başlangıçta bu sizi rahatsız edebilir, ancak uzun vadede tükenmişliği önlemek için bu sınırlar zorunludur.\n\n4.  **Ağ Oluşturmayı Bir Proje Olarak Görün:** Sosyal etkinliklerden kaçınmak yerine, bunu işinizin stratejik bir parçası olarak ele alın. Her ay katılmanız gereken bir veya iki sektör etkinliği belirleyin. Amacınız herkesle sohbet etmek değil, sadece iki veya üç anlamlı bağlantı kurmak olsun. Bu, görevi daha yönetilebilir ve daha az yorucu hale getirecektir.\n\n5.  **Bir "Dışadönük" Müttefik Bulun:** Kendi işinizi kurarken, sizin analitik ve operasyonel gücünüzü tamamlayacak, satış ve pazarlama konusunda doğal yeteneği olan bir ortak veya kilit çalışan bulun. Her şeyi tek başınıza yapmak zorunda değilsiniz. Zayıf yönlerinizi kabul etmek ve bu boşlukları başkalarıyla doldurmak bir güç göstergesidir.\n\n6.  **Stres İçin Fiziksel Bir Çıkış Yolu Geliştirin:** Yüzme ve doğa yürüyüşü harika. Stres anında kullanabileceğiniz daha yoğun bir fiziksel aktivite eklemeyi düşünün (örneğin, tempolu koşu, boks). Fiziksel yorgunluk, zihinsel ruminasyonu (aynı şeyleri tekrar tekrar düşünmeyi) kırmanın en etkili yollarından biridir.\n\n7.  **Duygusal Farkındalık Pratiği Yapın:** Günde 5-10 dakika ayırarak o an ne hissettiğinizi (stresli, yorgun, heyecanlı vb.) yargılamadan sadece isimlendirmeye çalışın. Analitik zihniniz duyguları birer "çözülmesi gereken sorun" olarak görebilir. Oysa bazen duyguların sadece fark edilmeye ve kabul edilmeye ihtiyacı vardır.\n\n8.  **"Başarı" Tanımınızı Genişletin:** Finansal özgürlüğün ötesinde, sizin için başarılı bir hayatın ne anlama geldiğini düşünün. Bu tanıma sağlık, ilişkiler, huzur ve öğrenme gibi unsurları da dahil edin. Bu, tek bir hedefe aşırı odaklanarak hayatın diğer alanlarını ihmal etmenizi önleyecektir.\n\n## Kendi Sözlerinizden: Anılar ve Anlam\n\nKendi ifadeleriniz, test sonuçlarının ortaya koyduğu tabloyu hem doğruluyor hem de ona derinlik katıyor. Bu, sadece soyut bir profil değil, sizin yaşadığınız gerçekliğin bir yansımasıdır.\n\n**Hedefleriniz ve Zorluklarınız:** Hayat amacınızı "**Kendi işimi kurmak ve finansal özgürlüğe ulaşmak**" olarak tanımlıyorsunuz. Bu, yüksek sorumluluk ve bağımsızlık ihtiyacınızın somut bir ifadesidir. En büyük zorluğunuz ise "**İş-yaşam dengesi ve stres yönetimi**". Bu iki ifade, madalyonun iki yüzü gibidir. Sizi hedeflerinize taşıyan aynı yoğun çalışma ahlakı, aynı zamanda sizi tüketen mekanizmadır. Bu, sizin merkezi yaşam geriliminizdir.\n\n**Güçlü Yönleriniz:** Kendinizi "**Analitik düşünme, sorumluluk, hızlı öğrenme**" ile tanımlıyorsunuz. Bu, test sonuçlarıyla birebir örtüşüyor. Kendi gücünüzün farkındasınız ve bu yetenekleri bilinçli olarak kullanıyorsunuz. Bu öz-farkındalık, gelişim için sağlam bir temeldir.\n\n**Mutluluk Anınız:** En mutlu anınız olarak "**Üniversiteden mezun olduğum gün**"ü belirtmeniz çok anlamlı. Bu an, rastgele bir keyif anı veya sosyal bir olay değil; uzun süreli, disiplinli bir çabanın sonucunda ulaşılan bir başarıdır. Bu, sizin için mutluluğun büyük ölçüde **hedefe ulaşma ve görev tamamlama** ile bağlantılı olduğunu gösteriyor. Bu bir güç olabilir, ancak aynı zamanda sizi süreçten keyif almaktan alıkoyan bir tuzak da olabilir. Hayat sadece varış noktalarından ibaret değildir; yolculuğun kendisi de önemlidir.\n\nBu ifadelerden çıkan üç temel içgörü şunlardır:\n1.  **Başarı Odaklı Motivasyon:** Sizi harekete geçiren temel güç, somut hedeflere ulaşmaktır. Bu sizi inanılmaz derecede etkili kılar.\n2.  **Sürdürülebilirlik Krizi:** Mevcut çalışma tarzınız ve stresle başa çıkma yöntemleriniz sürdürülebilir değil. Bir değişiklik yapılmazsa, tükenmişlik kaçınılmaz bir sonuç gibi görünüyor.\n3.  **İçsel Referans Noktası:** Değer ve mutluluk ölçütleriniz büyük ölçüde içsel standartlarınıza ve hedeflerinize ulaşmanıza bağlı. Dışsal onay veya sosyal popülerlik sizin için ikincil planda kalıyor.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, psikolojide kabul görmüş çeşitli kişilik modellerine dayanmaktadır. **Beş Faktör Kişilik Modeli (Big Five/OCEAN)**, kişiliğin beş temel boyutunu (Deneyime Açıklık, Sorumluluk, Dışadönüklük, Uyumluluk, Duygusal Denge) ölçen, bilimsel olarak en geçerli ve güvenilir model olarak kabul edilir. Sorumluluk puanınızın yüksekliği, akademik ve profesyonel başarı, daha iyi sağlık alışkanlıkları ve uzun ömür gibi olumlu yaşam sonuçlarıyla güçlü bir şekilde ilişkilidir. Düşük dışadönüklük puanınız ise, daha az risk alma eğilimi ve daha derin ama daha az sayıda sosyal ilişki gibi örüntülerle tutarlıdır.\n\n**MBTI (Myers-Briggs Tipi Göstergesi)**, tam bir profil çıkaracak kadar verimiz olmasa da, karar verme ve bilgi işleme tercihlerine odaklanır. Düşük dışadönüklük puanınıza dayanarak yaptığımız İçedönüklük (I) çıkarımı, enerjinizi nasıl yönlendirdiğinizi anlamamıza yardımcı olur. MBTI, bir tanı aracı olmaktan çok, kişisel farkındalık ve ekip dinamiklerini anlama konusunda bir çerçeve sunar.\n\nBu modellerin hiçbiri geleceği tahmin edemez veya sizi bir kutuya hapsetmez. Aksine, doğal eğilimlerinizi, potansiyel güçlü yönlerinizi ve dikkat etmeniz gereken risk alanlarını gösteren birer harita gibidirler. Davranışlarınız, bu temel eğilimler ile içinde bulunduğunuz durumun, hedeflerinizin ve bilinçli seçimlerinizin bir etkileşimidir. Bu raporun amacı, size bu haritayı sunarak, yolunuzu daha bilinçli bir şekilde çizmenize yardımcı olmaktır.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilendirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-20 23:03:02.252039+03	2025-08-20 23:04:20.022982+03	{"language": "tr", "language_ok": true}
dbb4114f-6b88-4bfb-832c-45f03788c830	2a1881bf-51c8-4726-ad0e-4206633e351d	self	completed	{"S0_AGE": 28, "S0_GENDER": "Erkek", "S0_LIFE_GOAL": "Kendi işimi kurmak", "S0_HAPPY_MEMORY": "Mezuniyet günü", "S0_TOP_STRENGTHS": "Analitik düşünme", "S0_TOP_CHALLENGES": "Stres yönetimi"}	{"S1_BIG5_001": 4, "S1_BIG5_002": 5, "S1_BIG5_003": 3, "S1_BIG5_004": 2, "S1_BIG5_005": 4, "S1_BIG5_006": 5, "S1_BIG5_007": 3, "S1_BIG5_008": 4, "S1_BIG5_009": 5, "S1_BIG5_010": 3, "S1_DISC_001": "A", "S1_DISC_002": "B", "S1_DISC_003": "A", "S1_DISC_004": "B", "S1_MBTI_001": 2, "S1_MBTI_002": 4, "S1_MBTI_003": 1, "S1_MBTI_004": 3}	Hazır mısın? Başlayalım..\n\nGerektiğinde sivri dilli olabilirim. Dünyayı okuma biçimim tavizsiz bir şekilde doğrudandır. Amacım seni daha güçlü ve mutlu kılmak; bu yüzden bazen seni sert bir şekilde eleştireceğim—seni küçümsemek için asla, seni gerçekliğe demirlemek için her zaman.\n\n| Özellik / Boyut | Puan |\n|----------------------------------|--------------|\n| **MBTI Tipi** | ENTP |\n| MBTI Dışadönüklük (E) | 65% |\n| MBTI İçedönüklük (I) | 35% |\n| MBTI Duyusal (S) | 35% |\n| MBTI Sezgisel (N) | 65% |\n| MBTI Düşünen (T) | 80% |\n| MBTI Hisseden (F) | 20% |\n| MBTI Yargılayan (J) | 50% |\n| MBTI Algılayan (P) | 50% |\n| **Big Five - Deneyime Açıklık (O)** | 63% |\n| **Big Five - Sorumluluk (C)** | 38% |\n| **Big Five - Dışadönüklük (E)** | 38% |\n| **Big Five - Uyumluluk (A)** | 75% |\n| **Big Five - Nevrotiklik (N)** | 13% |\n| **DISC - Dominantlık (D)** | 25% |\n| **DISC - Etkileyicilik (I)** | 25% |\n| **DISC - Durağanlık (S)** | 25% |\n| **DISC - Kuralcılık (C)** | 25% |\n| Bağlanma - Kaygı | Yetersiz veri |\n| Bağlanma - Kaçınma | Yetersiz veri |\n| Çatışma Stili (Birincil) | Yetersiz veri |\n| Duygu Düzenleme - Yeniden Değerlendirme| Yetersiz veri |\n| Duygu Düzenleme - Bastırma | Yetersiz veri |\n| Empati - Duygusal İlgi | Yetersiz veri |\n| Empati - Perspektif Alma | Yetersiz veri |\n\n## Temel Kişiliğin\n\nKişilik profilin, ender rastlanan ve güçlü bir kombinasyon sergiliyor: **analitik bir akıl ile işbirlikçi bir ruhu** bir araya getiriyorsun. Özünde, karmaşık sistemleri anlamaya, olasılıkları keşfetmeye ve fikirleri entelektüel düzeyde tartışmaya yönelik doymak bilmez bir arzuyla hareket eden bir **ENTP (Tartışmacı)** arketipisin. Ancak bu basit bir etiket değil; verilerindeki çelişkiler, seni daha karmaşık ve ilgi çekici kılıyor.\n\nEn belirgin çelişki, dışadönüklük seviyende yatıyor. MBTI testin, sosyal etkileşimden ve fikir alışverişinden enerji aldığını gösterirken (Dışadönüklük %65), Big Five sonuçların daha seçici ve içedönük davranışlara (Dışadönüklük %38) işaret ediyor. Bu, klasik bir "parti canavarı" olmadığın anlamına gelir. Sen bir **ambivert** ya da daha doğrusu **sosyal olarak seçici bir dışadönüksün**. Enerjini, yüzeysel sohbetlerin yapıldığı kalabalık ortamlarda harcamak yerine, zekice tartışmalar yapabileceğin küçük ve güvendiğin bir çevreyle etkileşime girmeyi tercih ediyorsun.\n\nİkinci ve daha önemli çelişki, mantık ve uyum arasındaki dengedir. Çok güçlü bir Düşünme (T) eğilimin (%80) var; bu da kararlarını objektif verilere ve mantıksal tutarlılığa dayandırdığını gösteriyor. Genellikle bu özellik, daha düşük bir uyumlulukla ilişkilendirilir. Ancak senin Uyumluluk (A) puanın oldukça yüksek (%75). Bu, seni **ilkeli ama soğuk olmayan, analitik ama insanları kırmayan** biri yapıyor. Bir problemi, insanları yabancılaştırmadan, salt mantıkla parçalarına ayırabilirsin. Amacın bir tartışmayı kazanmaktan ziyade, en mantıklı ve herkes için en adil çözümü bulmaktır.\n\nAncak en büyük zorluğun, parlak zekan ile eylemlerin arasındaki boşlukta yatıyor. Düşük Sorumluluk (C) puanın (%38), esnek ve anlık hareket etmeye yönelik Algılayan (P) eğiliminle birleştiğinde, hayatının en büyük engelini oluşturuyor: **başlama konusunda harikasın, bitirme konusunda zayıfsın.** Bu durum, özellikle "kendi işini kurma" hedefin için kritik bir tehdittir. DISC profilinin dengeli yapısı (%25 her alanda), duruma göre davranışlarını ayarlayabilen bir bukalemun olduğunu gösteriyor. Bu adaptasyon yeteneği bir güç olsa da, aynı zamanda net bir itici güç veya kararlı bir duruş eksikliğine de işaret edebilir.\n\n## Güçlü Yönlerin\n\n*   **Analitik ve Stratejik Zeka:** Yüksek Düşünme ve Sezgisellik puanların, soyut kavramları anlama, kalıpları görme ve karmaşık stratejiler geliştirme konusunda sana doğal bir yetenek veriyor. Kendi belirttiğin "analitik düşünme" gücün, verilerle de doğrulanıyor. Bu, özellikle iş kurma hedefinde vizyonu belirlemek için en büyük sermayen.\n\n*   **İşbirlikçi Mantık:** Yüksek Düşünme ve yüksek Uyumluluk gibi nadir bir kombinasyona sahipsin. Bu, seni hem rasyonel hem de diplomatik kılar. İnsanları zorlamak yerine mantıkla ikna edersin. Ekip içinde hem en akıllıca çözümü bulabilir hem de bu süreçte uyumu koruyabilirsin.\n\n*   **Duygusal Denge:** Nevrotiklik puanının (%13) olağanüstü derecede düşük olması, temelden sakin, dayanıklı ve strese karşı dirençli bir yapıya sahip olduğunu gösteriyor. Baskı altında soğukkanlılığını korursun ve küçük aksiliklerin moralini bozmasına izin vermezsin. Bu, bir girişimcinin sahip olabileceği en değerli özelliklerden biridir.\n\n*   **Durumsal Uyum Yeteneği:** Dengeli DISC profilin, farklı durumlarda farklı şapkalar takabildiğini gösteriyor. Gerektiğinde doğrudan ve kararlı (Dominant), gerektiğinde ikna edici ve sosyal (Etkileyici), gerektiğinde destekleyici ve sabırlı (Durağan) veya dikkatli ve kuralcı (Kuralcı) olabilirsin. Bu esneklik, seni çok yönlü bir problem çözücü yapar.\n\n## Kör Noktalar ve Riskler\n\n*   **Kronik Erteleme ve Düzensizlik:** Bu, Aşil topuğun. Düşük Sorumluluk (%38) puanın, girişimcilik hedefinin önündeki en büyük engeldir. Fikirler harika olabilir, ancak planlama, takip ve uygulama olmadan hiçbir değeri yoktur. Bu zayıflık, teslim tarihlerini kaçırmana, önemli detayları gözden kaçırmana ve en nihayetinde projelerin başarısız olmasına yol açabilir.\n\n*   **"Parlak Nesne" Sendromu:** Yüksek Deneyime Açıklık ve Sezgisellik, düşük Sorumluluk ile birleştiğinde, sürekli olarak yeni ve daha heyecan verici bir fikrin peşinden gitme eğilimi yaratır. Bir projeyi tamamlamadan diğerine atlarsın. Bu, enerjini dağıtır ve somut bir başarı inşa etmeni engeller.\n\n*   **Stresin Kaynağını Yanlış Anlama:** En büyük zorluğunun "stres yönetimi" olduğunu belirtmişsin. Bu, aşırı düşük Nevrotiklik puanınla tam bir çelişki içindedir. Bu durum, stresinin kaynağının duygusal olmadığını, **davranışsal** olduğunu gösteriyor. Sen, içsel bir kaygıdan dolayı stres yaşamıyorsun; düzensizliğinin ve erteleme alışkanlığının yarattığı **kaosun sonuçlarından** dolayı strese giriyorsun. Son teslim tarihlerinin baskısı, kaçırılan fırsatlar ve plansızlıktan kaynaklanan krizler seni strese sokuyor. Sorun hislerinde değil, sistemlerinde.\n\n*   **Etkisiz Kalan Bir İtici Güç:** Dengeli DISC profilin adaptasyon yeteneği sunsa da, kritik anlarda net bir liderlik veya uzmanlık tarzı sergilemeni engelleyebilir. Girişimcilik, bazen acımasızca Dominant olmayı, bazen de titizlikle Kuralcı olmayı gerektirir. Her şey olmaya çalışmak, hiçbir şeyde uzmanlaşamama riskini taşır.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişkilerde, yüksek Uyumluluk puanın seni sıcak, düşünceli ve işbirlikçi bir partner yapar. Entelektüel bağ kurmaya büyük önem verirsin; senin için ideal bir partner, fikirlerini tartışabileceğin, zihinsel olarak seni zorlayan biridir. Ambivert yapın nedeniyle, büyük partiler veya kalabalık sosyal etkinlikler yerine, birkaç yakın dostunla derin sohbetler etmeyi tercih edersin.\n\nAncak, en büyük çatışma potansiyeli yine düşük Sorumluluk özelliğinden kaynaklanır. Verdiğin sözleri unutabilir, planları son anda değiştirebilir veya günlük sorumlulukları aksatabilirsin. Bu durum, partnerin için yorucu ve istikrarsız bir dinamik yaratabilir. Bir sorunla karşılaştığında, duygusal destek sunmak yerine mantıksal bir "çözüm" bulmaya çalışma eğilimin (yüksek Düşünme), iyi niyetli olsa bile partnerin tarafından duygusal olarak mesafeli algılanabilir.\n\n## Kariyer ve Çalışma Tarzı\n\nSenin için ideal olan, yaratıcı problem çözmeyi, stratejik düşünmeyi ve özerkliği ödüllendiren rollerdir. Strateji danışmanlığı, Ar-Ge, sistem tasarımı veya bir girişimin vizyoner kurucusu olmak gibi pozisyonlar sana mükemmel uyar. Fikir üretme ve büyük resmi görme yeteneğin bu alanlarda parlar. Buna karşılık, detay odaklı, tekrarlayan ve katı kurallara bağlı idari işler seni boğar ve performansını düşürür.\n\n"Kendi işimi kurma" hedefin, güçlü yönlerinle (Sezgisellik, Düşünme) mükemmel bir şekilde örtüşüyor, ancak zayıf yönün (Sorumluluk) nedeniyle devasa bir risk taşıyor. Sen, işin **beyni ve vizyoneri** olabilirsin. Ancak bu vizyonu gerçeğe dönüştürecek, operasyonları yönetecek, finansal tabloları takip edecek ve süreçleri uygulayacak **son derece sorumlu bir ortağa veya operasyon direktörüne (COO) mutlak surette ihtiyacın var.** Bu, senin için bir lüks değil, bir zorunluluktur. Başarın, bu eksiğini nasıl telafi ettiğine bağlı olacaktır.\n\n## Duygusal Desenler ve Stres\n\nTekrar vurgulamak gerekirse, senin stresin içsel bir fırtınadan değil, dışsal bir kaostan kaynaklanıyor. Varsayılan durumun sakinliktir (düşük Nevrotiklik). Seni strese sokan tetikleyiciler, kendi eylemsizliğinin veya plansızlığının biriktirdiği dış baskılardır: haftalardır görmezden geldiğin bir projenin teslim tarihinin yaklaşması gibi.\n\nBu tür bir stresle başa çıkma yöntemin muhtemelen daha fazla düşünmektir. Sorunu analiz etmeye, mantıksal bir çıkış yolu bulmaya çalışırsın. Bu, teknik sorunlar için işe yarar, ancak disiplin eksikliğinden kaynaklanan sorunlar için tamamen işlevsizdir. Dağınık bir odayı analiz ederek temizleyemezsin; sadece temizlemen gerekir.\n\n## Yaşam Desenleri ve Muhtemel Tuzaklar\n\nEğer mevcut gidişatını değiştirmezsen, "parlak ama potansiyelini gerçekleştirememiş" arketipine dönüşme riskin var. Hayatın, %80'i tamamlanmış sayısız ilginç proje ile dolu olabilir. Kariyerinde, derin bir ustalık veya dönüm noktası niteliğinde bir başarı elde etmek yerine, ilginç işler veya girişimler arasında geçiş yapabilirsin. Bu geniş bir deneyim birikimi sağlar, ancak somut ve kalıcı bir miras bırakmanı engeller.\n\nHayatındaki temel değiş tokuş şudur: **güvenilirliği esneklikle takas ediyorsun.** Hedeflerine ulaşmak için, doğana aykırı gelse bile bu dengeyi bilinçli olarak güvenilirlik lehine kaydırmak zorundasın. Bu, özgürlüğünden vazgeçmek değil, yaratıcılığının meyve vereceği bir yapı inşa etmektir.\n\n## Eyleme Geçirilebilir İleriye Dönük Yol Haritası\n\n1.  **Sorumlu Bir Ortak Bul:** İş hedefin için, Excel tablolarını, proje planlarını ve son teslim tarihlerini seven bir kurucu ortak bul. Bu, atabileceğin en önemli adımdır. Kişisel hayatında da, seni yapılandırma konusunda destekleyen bir partnere değer ver.\n\n2.  **Yapıyı Dışsallaştır:** İrade gücüne güvenme. İrade, tükenen bir kaynaktır. Bunun yerine, sistemlere güven. Takvimler, proje yönetimi araçları (Trello, Asana gibi), alarmlar ve hatırlatıcıları acımasızca kullan. Senin için başkaları tarafından belirlenen teslim tarihleri yarat.\n\n3.  **"İki Dakika Kuralı"nı Uygula:** Eğer bir görev iki dakikadan az sürüyorsa, hemen yap. Bu, "daha sonra yaparım" ataletini kırar ve küçük ama önemli işlerin birikmesini engeller (örneğin, bir e-postayı yanıtlamak).\n\n4.  **"Stres" Tanımını Değiştir:** "Stres yönetimi" sorununu bir "sistem yönetimi" sorunu olarak yeniden çerçevele. Stresli hissettiğinde, "Neden böyle hissediyorum?" diye sorma. Bunun yerine, "Hangi sistem çöktü?" veya "Hangi planı uygulamadım?" diye sor.\n\n5.  **Özgürlüğünü Planla:** Algılayan (P) doğan, spontanlığa ihtiyaç duyar. Öyleyse, onu planla. Takvimine "serbest düşünme zamanı" veya "yapılandırılmamış günler" ekle. Böylece esneklik ihtiyacın, tüm haftanı rayından çıkarmaz.\n\n6.  **Mantık+Uyum Gücünü Kullan:** Müzakerelerde veya anlaşmazlıklarda, hem mantıklı hem de nazik olma yeteneğine bilinçli olarak yaslan. Argümanlarını nesnel verilere ve ortak ilkelere dayandırırken, karşı tarafın bakış açısını anladığını ve saygı duyduğunu göster.\n\n7.  **Tek Bir Şeyi Bitir:** Önemli bir kişisel veya profesyonel proje seç ve yeni bir şeye başlamadan önce onu %100 tamamlamaya odaklan. Bu, "bitirme kasını" geliştirir ve bunu yapabileceğini kendine kanıtlar.\n\n8.  **Disiplini Yeniden Anlamlandır:** Disiplini bir ceza olarak değil, yaratıcılığının gelişmesini sağlayan bir çerçeve olarak gör. Bir sarmaşığı destekleyen çit onun için bir kafes değildir; güneşe doğru büyümesini sağlayan yapıdır. Senin sistemlerin, senin çitin olacak.\n\n## Kendi Sözlerinle: Anılar ve Anlam\n\nAnalizlerimizi, senin kendi ifadelerinle birleştirelim. Bunlar, soyut verilerin ötesinde, senin yaşayan deneyimindir.\n\n*   **Hedefin: "Kendi işimi kurmak."** Bu, ENTP profilinin özerklik, meydan okuma ve fikir üretme arzusunun nihai bir ifadesidir. Bu hedef, kim olduğunun bir yansımasıdır ve peşinden gitmeye değer. Ancak yukarıda belirtilen riskler, bu hedefe giden yoldaki mayınlardır.\n\n*   **Güçlü Yönün: "Analitik düşünme."** Kendini doğru tanıyorsun. Bu, %80'lik Düşünme puanınla tamamen uyumlu. Bu senin kimliğinin bir parçası ve en güvendiğin aracın.\n\n*   **Zorluğun: "Stres yönetimi."** Bu, en aydınlatıcı ifaden. Düşük Nevrotiklik puanınla olan çelişkisi, stresinin kaynağının duygusal değil, davranışsal ve durumsal olduğunu kanıtlıyor. Yaşadığın stres gerçek, ancak kaynağı yanlış teşhis edilmiş.\n\n*   **Mutlu Anın: "Mezuniyet günü."** Bu anı, bir **başarı ve tamamlanma** anısıdır. Uzun, yapılandırılmış bir projenin başarılı bir şekilde sonunu işaret eder. Bu, senin için güçlü bir duygusal çıpadır. Erteleme ile mücadele ettiğinde, o gün hissettiğin gururu ve rahatlamayı hatırlamak, güçlü bir motivasyon kaynağı olabilir. Bu anı, doğana karşı gelip bir şeyi sonuna kadar götürdüğünde nelerin mümkün olduğunu temsil ediyor.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, psikolojide kabul görmüş çeşitli modellere dayanmaktadır. **Big Five (Beş Faktör) modeli**, kişiliğin temel ve istikrarlı özelliklerini tanımlar. Sorumluluk (Conscientiousness) gibi özelliklerin akademik ve profesyonel başarıyı, Nevrotikliğin (Neuroticism) ise strese karşı duyarlılığı öngörmede ne kadar güçlü olduğu kanıtlanmıştır. Senin düşük Sorumluluk ve düşük Nevrotiklik profilin, hem büyük bir potansiyeli hem de çok özel bir zorluğu bir arada barındıran nadir bir durumdur.\n\n**MBTI (Myers-Briggs Tip Göstergesi)**, bir kişilik testi olmaktan çok, bilgiyi nasıl işlediğine ve kararları nasıl verdiğine dair bir tercih modelidir. Senin ENTP tipin, olasılıkları keşfetme (Sezgisellik) ve bunları mantıksal çerçevelerle (Düşünme) analiz etme tercihini vurgular. Raporumuzdaki en derinlemesine analizler, MBTI ve Big Five verileri arasındaki çelişkilerden (Dışadönüklük ve Uyumluluk gibi) doğmuştur, çünkü bu nüanslar seni standart bir kalıbın dışına çıkarır.\n\n**DISC modeli**, özellikle iş ve ekip ortamlarındaki gözlemlenebilir davranış tarzını açıklar. Senin dengeli profilin, davranışsal esnekliğini gösterir. Bu modellerin hiçbiri tek başına tam bir resim sunmaz. Güçleri, bir araya geldiklerinde ortaya çıkar: Big Five **ne olduğunu** (temel özelliklerin), MBTI **nasıl düşündüğünü** (bilişsel tercihlerin) ve DISC **nasıl davrandığını** (durumsal eylemlerin) açıklar. Bu rapor, bu katmanları birleştirerek, seni daha bütünsel bir şekilde anlamayı hedefler ve önerilerini bu entegre anlayış üzerine kurar.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilendirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-20 23:08:29.830147+03	2025-08-20 23:10:18.607552+03	{"language": "tr", "language_ok": true}
2baa8322-7c04-42f5-b0c2-696e03b7ae4b	f55dfb24-6a6e-495d-86c7-897a73ffcb88	self	completed	{"S0_AGE": 30, "S0_GENDER": "Kadın", "S0_LIFE_GOAL": "Test amaç"}	{"S1_BIG5_001": 5, "S1_BIG5_002": 4}	Hazır mısınız? Başlayalım..\n\nGerektiğinde sivri dilli olabilirim. Dünyayı okuma biçimim özür dilemeksizin doğrudandır. Amacım sizi daha güçlü ve mutlu kılmaktır; bu yüzden zaman zaman sizi sert bir şekilde eleştireceğim - asla sizi küçümsemek için değil, her zaman sizi gerçeğe demirlemek için.\n\n| Özellik / Boyut | Puan |\n|-----------------------------------|---------------------------------|\n| **MBTI Tipi** | Hesaplama için yetersiz veri |\n| MBTI Dışadönüklük (E) | Hesaplama için yetersiz veri |\n| MBTI İçedönüklük (I) | Hesaplama için yetersiz veri |\n| MBTI Duyumsama (S) | Hesaplama için yetersiz veri |\n| MBTI Sezgi (N) | Hesaplama için yetersiz veri |\n| MBTI Düşünme (T) | Hesaplama için yetersiz veri |\n| MBTI Hissetme (F) | Hesaplama için yetersiz veri |\n| MBTI Yargılama (J) | Hesaplama için yetersiz veri |\n| MBTI Algılama (P) | Hesaplama için yetersiz veri |\n| **Big Five - Deneyime Açıklık (O)** | Hesaplama için yetersiz veri |\n| **Big Five - Sorumluluk (C)** | Hesaplama için yetersiz veri |\n| **Big Five - Dışadönüklük (E)** | Hesaplama için yetersiz veri |\n| **Big Five - Uyumluluk (A)** | Hesaplama için yetersiz veri |\n| **Big Five - Duygusal Dengesizlik (N)** | Hesaplama için yetersiz veri |\n| **DISC - Hakimiyet (D)** | Hesaplama için yetersiz veri |\n| **DISC - Etki (I)** | Hesaplama için yetersiz veri |\n| **DISC - Kararlılık (S)** | Hesaplama için yetersiz veri |\n| **DISC - Uyum (C)** | Hesaplama için yetersiz veri |\n| Bağlanma - Kaygı | Hesaplama için yetersiz veri |\n| Bağlanma - Kaçınma | Hesaplama için yetersiz veri |\n| Çatışma Stili (Birincil) | Hesaplama için yetersiz veri |\n| Duygu Düzenleme - Yeniden Değerlendirme| Hesaplama için yetersiz veri |\n| Duygu Düzenleme - Bastırma | Hesaplama için yetersiz veri |\n| Empati - Duygusal İlgi | Hesaplama için yetersiz veri |\n| Empati - Perspektif Alma | Hesaplama için yetersiz veri |\n\n## Temel Kişiliğiniz\n\nKişilik profilinizi kapsamlı bir şekilde analiz etmek için gerekli olan MBTI, Big Five ve DISC değerlendirmelerine verdiğiniz yanıtlar mevcut değil veya yetersiz. Bu temel veriler olmadan, davranışsal eğilimleriniz, bilişsel tercihleriniz ve temel mizaç özellikleriniz hakkında anlamlı bir portre çizmek mümkün değildir. Bu analiz, kişiliğinizin farklı durumlarda nasıl tezahür ettiğini anlamak için bu üç modelin entegrasyonuna dayanır; ancak bu veri eksikliği nedeniyle şu anda size özel bir analiz sunamıyorum.\n\n## Güçlü Yönler\n\nGüçlü yönlerinizi belirlemek, kişilik testlerinden elde edilen puanların yanı sıra kendi bildirdiğiniz yetkinliklerin bir analizini gerektirir. Psikometrik verileriniz olmadan, hangi özelliklerin sizin için doğal bir avantaj sağladığını objektif olarak değerlendiremem. Örneğin, yüksek Sorumluluk (Conscientiousness) puanı genellikle güvenilirlik ve organizasyon becerisine işaret ederken, yüksek Etki (Influence) puanı ikna kabiliyetini gösterebilir. Bu veriler olmadan, güçlü yönleriniz hakkında yapılacak herhangi bir yorum spekülasyondan öteye geçemez.\n\n## Kör Noktalar ve Riskler\n\nBenzer şekilde, potansiyel kör noktalarınız ve risk alanlarınız da kişilik verilerinizle yakından ilişkilidir. Örneğin, yüksek Duygusal Dengesizlik (Neuroticism) strese karşı artan bir hassasiyete işaret edebilirken, düşük Uyumluluk (Agreeableness) kişilerarası çatışma riskini artırabilir. Bu değerlendirmeler yapılmadan, hangi davranış kalıplarının sizin için zorluk yaratabileceğini veya sizi istenmeyen sonuçlara sürükleyebileceğini belirlemek imkansızdır. Size özel, eyleme geçirilebilir geri bildirim sağlamak için bu temel ölçümlere ihtiyacım var.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişki kurma biçiminiz, çatışmaları nasıl yönettiğiniz ve sosyal ortamlardaki davranışlarınız, bağlanma stiliniz, empati düzeyiniz ve temel kişilik özelliklerinizden büyük ölçüde etkilenir. Bağlanma, çatışma stili ve empati testlerine verdiğiniz yanıtlar olmadan, sosyal dinamikleriniz hakkında derinlemesine bir analiz yapamam. Bu veriler, yakın ilişkilerde, arkadaşlıklarda ve ekip çalışmalarında karşılaşabileceğiniz olası zorlukları ve bu zorluklarla başa çıkma stratejilerini anlamak için kritik öneme sahiptir.\n\n## Kariyer ve Çalışma Tarzı\n\nDISC profili, iş yerindeki davranışsal tarzınızı anlamak için temel bir araçtır. Hakimiyet, Etki, Kararlılık ve Uyum boyutlarındaki eğilimleriniz, liderlik potansiyelinizi, ekip içindeki rolünüzü, karar alma süreçlerinizi ve hangi çalışma ortamlarında en verimli olacağınızı gösterir. Bu veri olmadan, kariyerinize uygun roller, potansiyel mesleki zorluklar veya performansınızı artıracak koşullar hakkında size özel ve somut tavsiyeler sunmak mümkün değildir.\n\n## Duygusal Desenler ve Stres\n\nDuygusal tepkilerinizi ve stresle başa çıkma mekanizmalarınızı anlamak, Duygusal Dengesizlik (Neuroticism) puanınıza ve duygu düzenleme stratejilerinize (yeniden değerlendirme, bastırma) bağlıdır. Bu veriler, sizi neyin tetiklediğini, stres altında varsayılan tepkilerinizin ne olduğunu ve duygusal tırmanışları nasıl önleyebileceğinizi anlamamıza yardımcı olur. Bu bilgiler olmadan, duygusal sağlığınızı yönetmenize yönelik kişiselleştirilmiş bir rehberlik sunamam.\n\n## Yaşam Desenleri ve Olası Tuzaklar\n\nKişilik profilleri, bireylerin yaşamları boyunca karşılaşabilecekleri belirli fırsatları ve tuzakları öngörmemize yardımcı olabilir. Örneğin, yüksek Deneyime Açıklık ve düşük Sorumluluk sahibi bir kişi, birçok projeye başlayıp hiçbirini bitirmeme tuzağına düşebilir. Sizin profiliniz hakkında veri olmadan, yaşam yolunuzda karşınıza çıkabilecek olası desenler, avantajlar veya zorluklar hakkında gerçekçi öngörülerde bulunamam.\n\n## Eyleme Geçirilebilir İleriye Dönük Yol\n\nMevcut durumda, size özel ve derinlemesine tavsiyeler sunmak için yeterli veriye sahip değilim. Bu nedenle, en önemli ve tek eylem planı, bu analizin temelini oluşturan psikolojik değerlendirmeleri tamamlamanızdır.\n\n*   **Değerlendirmeleri Tamamlayın:** Size doğru ve faydalı bir analiz sunabilmem için ilk adım, kişilik, davranış ve ilişki tarzlarınızı ölçen testleri eksiksiz bir şekilde tamamlamaktır. Bu, size sunacağım içgörülerin isabetliliği için temel bir gerekliliktir.\n*   **Dürüst ve İçten Yanıtlar Verin:** Testleri yanıtlarken, ideal benliğinizi değil, mevcut durumunuzu en dürüst şekilde yansıtan cevapları seçin. Analizin doğruluğu, verdiğiniz yanıtların samimiyetine bağlıdır.\n*   **Kişisel Hedeflerinizi Netleştirin:** Değerlendirmeleri tamamlarken, bu süreçten ne elde etmek istediğinizi düşünün. İlişkilerinizi mi geliştirmek istiyorsunuz, kariyerinizde mi netlik arıyorsunuz, yoksa kendinizi daha iyi anlamak mı istiyorsunuz? Hedefleriniz ne kadar net olursa, analiz o kadar odaklı olur.\n*   **Açık Uçlu Sorulara Zaman Ayırın:** En mutlu anılarınız, en zorlu deneyimleriniz ve hedefleriniz gibi açık uçlu sorular, sayısal verilerin ötesinde bir derinlik katmaktadır. Bu bölümleri düşünerek ve ayrıntılı bir şekilde doldurmak, analizin kalitesini önemli ölçüde artıracaktır.\n\nBu adımları tamamladıktan sonra, size özel, derinlemesine ve eyleme geçirilebilir bir analiz sunmak mümkün olacaktır.\n\n## Kendi Sözlerinizle: Anılar ve Anlam\n\nAnaliz için gerekli olan anılarınızı, hedeflerinizi veya zorluklarınızı paylaşmadınız. Ancak, "yaşam amacı" sorusuna verdiğiniz yanıt, mevcut durumunuz hakkında önemli bir ipucu veriyor.\n\nYaşam amacınız olarak **"Test amaç"** ifadesini kullandınız.\n\nBu yanıt, şu anda bu sürece derinlemesine bir kendini keşif yolculuğu olarak değil, daha çok sistemin nasıl çalıştığını görmek için bir deneme olarak yaklaştığınızı gösteriyor. Bu, yargılanacak bir durum değildir; aksine, temkinli ve analitik bir yaklaşımın işareti olabilir. Bir sisteme tam olarak yatırım yapmadan önce onu test etme, sınırlarını anlama ve güvenilirliğini ölçme isteği, gerçekçi ve metodik bir zihniyeti yansıtır. Bu raporun şu anki sınırlılığı da bu başlangıç yaklaşımınızın doğal bir sonucudur. Daha derin bir analize hazır olduğunuzda, değerlendirmeleri tamamlama kararını verecek olan yine sizsiniz.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, psikolojide kabul görmüş ve yaygın olarak kullanılan çeşitli teorik çerçevelere dayanmaktadır. Size özel bir analiz sunamasam da bu çerçevelerin ne işe yaradığını açıklamak önemlidir.\n\n**Beş Faktör Kişilik Modeli (Big Five/OCEAN)**, kişiliğin temel yapısını beş ana boyutta (Deneyime Açıklık, Sorumluluk, Dışadönüklük, Uyumluluk, Duygusal Dengesizlik) ele alan, bilimsel olarak en sağlam ve geçerli modeldir. Bu özellikler, iş başarısından ilişki memnuniyetine, ruh sağlığından yaşam süresine kadar birçok önemli yaşam sonucuyla tutarlı bir şekilde ilişkilendirilmiştir. Örneğin, yüksek Sorumluluk, akademik ve mesleki başarı için güçlü bir yordayıcıdır.\n\n**MBTI (Myers-Briggs Tipi Göstergesi)**, insanların dünyayı nasıl algıladığı ve kararlarını nasıl verdiği konusundaki psikolojik tercihleri ölçer. Dışadönüklük/İçedönüklük, Duyumsama/Sezgi, Düşünme/Hissetme ve Yargılama/Algılama olmak üzere dört temel ikilem üzerine kuruludur. MBTI, bir tanı aracı olmaktan çok, bireylerin bilişsel tarzlarını ve iletişim tercihlerini anlamalarına yardımcı olan bir çerçeve sunar.\n\n**DISC modeli** ise özellikle profesyonel ortamlardaki gözlemlenebilir davranışlara odaklanır. Hakimiyet (Dominance), Etki (Influence), Kararlılık (Steadiness) ve Uyum (Compliance) olmak üzere dört temel davranışsal eğilimi ölçer. Bu model, bir kişinin görevlere ve diğer insanlara nasıl yaklaştığını anlamak, ekip dinamiklerini iyileştirmek ve liderlik tarzını belirlemek için oldukça pratiktir.\n\nBu üç model bir araya geldiğinde, kişiliğinizin farklı katmanlarını (temel mizaç, bilişsel tercihler ve durumsal davranışlar) bütüncül bir şekilde görmemizi sağlar. Değerlendirmeleri tamamladığınızda, bu kanıta dayalı çerçeveler kullanılarak sizin için anlamlı ve eyleme geçirilebilir bir profil oluşturulacaktır.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilendirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-20 23:10:50.296525+03	2025-08-20 23:11:36.875448+03	{"language": "tr", "language_ok": true}
6fa4cad9-67eb-4e42-9ead-e80f8c7821df	ebe6eee2-01ae-4753-9737-0983b0330880	self	completed	{"S0_AGE": 46, "S0_LIKES": "arkadaşlarla sohbet ama şu an arkadaşım yok", "S0_COPING": "beni rahat hissettirecek yaşamların olduğu film veya diziler izlemek. örneğin yeni keşfedilen bir gezegendeki hayatı konu olan veya lise yıllarıma geri dönmemi sağlayacak olan bir lise dizisi veya yaşamak istediğim bir ülkede üyesi olmak isteyeceğim bir kasabada geçen bir film", "S0_GENDER": "Erkek", "S0_CONSENT": "Evet", "S0_HOBBIES": "yapay zeka, reverse aging, futbol, güzel kadınlar, tropik cennetler", "S0_DISLIKES": "aptal insanlarla muhattap olmak", "S0_TRIGGERS": "özgüvenli cehalet, kıskançlık, saygısızlık, yapma dediğin şeyin ısrarla yapılması, bir şeye konsantre iken birini ısrarla konsantrasyonumu bozacak işler yapması", "S0_WHY_NEED": "kendini tanımak, daha doğru kararlar alarak hayat kalitemi yükseltmek amacıyla", "S0_LIFE_GOAL": "Çok büyük bir şirkete sahip olmak. Bir ada satın alıp baştan sona kendi cennetimi yaratmak", "S0_LIVE_WITH": "Yalnız", "S0_NEAR_TERM": "Nerede yaşamak istediğim bilmiyorum. kendimi ait hissedebileceğim bir yer bulmam lazım. ayrıca işlerim kötüye gidiyor. bir an önce iyi bir getiri sağlayacak girişim yapmam gerekiyor", "S0_REL_GOALS": "Güven, uyum, saygı, hayatıma renk getirmesi, desteklenmek", "S0_WORK_PACE": "Serbest", "S0_BOUNDARIES": "Yalan, Aldatma, Saygısızlık", "S0_CHRONOTYPE": "Akşam", "S0_REL_STATUS": "Bekâr", "S0_STRESS_NOW": "4", "S0_CARE_DUTIES": "Evcil hayvan", "S0_COMMUTE_MIN": 1, "S0_SCHOOL_TYPE": "Lisans (Üniversite)", "S0_VALUES_TOP3": "Saygı,Özgürlük,Başarı", "S0_WORK_STATUS": "Çalışıyorum", "S0_SCHOOL_FIELD": "Girişimciyim", "S0_STUDY_ACTIVE": "Okumuyorum", "S0_SUPPORT_SIZE": 1, "S0_TOUCH_COMFORT": "3", "S0_TOP_CHALLENGES": "yalnızlık", "S0_LOVE_LANG_ORDER": "Temas,Kaliteli zaman,Hizmet", "S0_MONEY_TALK_EASE": "5", "S0_SOCIAL_VIS_EASE": "4", "S0_TIME_BUDGET_HRS": 12}	{"S1_NFC1": "4", "S1_BF_A1": "4", "S1_BF_A2": "3", "S1_BF_A3": "3", "S1_BF_A4": "3", "S1_BF_C1": "1", "S1_BF_C2": "2", "S1_BF_C3": "1", "S1_BF_C4": "1", "S1_BF_E1": "4", "S1_BF_E2": "4", "S1_BF_E3": "2", "S1_BF_E4": "3", "S1_BF_N1": "5", "S1_BF_N2": "4", "S1_BF_N3": "3", "S1_BF_N4": "4", "S1_BF_O1": "3", "S1_BF_O2": "2", "S1_BF_O3": "4", "S1_BF_O4": "4", "S1_TKI_1": "Beraber kısa bir toplantı yapıp kural + görev paylaşımı oluşturmayı öneririm.", "S1_TKI_4": "Netçe uyarır, yerime dönmesini isterim.", "S1_TKI_5": "Konuyu çözüme bağlamak için yönlendirir, somut adımlar belirlerim.", "S1_TKI_7": "Kanıtları sunar, kararı netleştiririm.", "S1_MB_FC1": "A", "S1_MB_FC2": "B", "S1_MB_FC3": "B", "S1_MB_FC4": "B", "S1_MB_FC5": "B", "S1_MB_FC6": "B", "S1_MB_FC7": "A", "S1_MB_FC8": "A", "S1_MB_FC9": "B", "S1_Q_ATTN": "4", "S1_Q_CONS": "5", "S1_AT_ANX1": "5", "S1_AT_ANX2": "5", "S1_AT_ANX3": "4", "S1_AT_ANX4": "5", "S1_AT_ANX5": "5", "S1_AT_ANX6": "4", "S1_AT_AVO1": "2", "S1_AT_AVO2": "4", "S1_AT_AVO3": "5", "S1_AT_AVO4": "4", "S1_AT_AVO5": "4", "S1_AT_AVO6": "4", "S1_EMP_EC1": "5", "S1_EMP_EC2": "4", "S1_EMP_PT1": "3", "S1_EMP_PT2": "4", "S1_MB_FC10": "B", "S1_MB_FC11": "B", "S1_MB_FC12": "A", "S1_OE_HARD": "köyde büyüdük. 1985 senesi. 8 yaşındayım. abimin bir metal kolyesi vardı. köy yerinde o dönemlerde bu tür şeyler çok önemli olabiliyor. abimin haksız olduğu bir kavgada kendimi savunurken kolyesini kopardım 2. 3 yerinden. abim çok kızmıştı çok da üzülmüştü. buna sebep olduğum için çok üzüldüm\\n\\nyaklaşık 14-15 yaşındayken babam beni dövdü. yağmur yağıyodu. evin alt tarafındaki ormana kaçtım. ağaçların altında hıçkıra hıçkıa ağlıyordum. babamdan nefret ediyordum, eve gitmek istemiyordum ama başka hiç bir seçeneğim yoktu. eve gitmek gururumu kırıyoordu, tekrar suçlanacağım, annemin babamın surat ifadesi ve bakışlarıyla bana şiddet uygulayacağı o eve gitmek istemiyordum. büyüyünce de başka çok problemim  olacak ben nasıl bunlarla başa çıkacağım diye çok üzülmüştüm.\\n\\nabimi askere 18 aylığına gönderirken de çok üzülmüştüm", "S1_OE_WEAK": "liderlik vasıflarım, sosyal yetenekler ve insanlar üzerinde daha yüksek etki, detaylara hakim olmak", "S1_Q_SPEED": "4", "S1_OE_HAPPY": "5 ay askerlik yaptım. günler geçmek bilmedi. askerliğim bittiği günün sabahına uyandığımda aşırı mutluydum. çünkü biraz sonra işlemlerimi tamamlayıp askeriyeden çıkıp özgür olacaktım. \\n\\nsibling olan iki kedim daha 5-6 aylıkken dermatit yüzüden 12 gün veterinerde kaldı. o esnada onları çok özledim kaygılandım ve 12 gün sonra, veterineler eve getirip kapı eşiğiden bıraktıklarında ve onları gördüğümde aşırı ama çok aşırı mutlu oldum", "S1_Q_REPEAT": "3", "S1_DISC_SJT1": "Ana vanayı kapatır, ustayı arar, gerekirse komşuyu bilgilendiririm.", "S1_DISC_SJT2": "Grubun ritmini gözlemler, kime nasıl destek olabileceğimi sorarım.", "S1_DISC_SJT3": "Fatura/garanti ve arıza notlarını toplayıp üretici kılavuzuna göre ilerlerim.", "S1_DISC_SJT4": "Alternatifleri süre/maliyet/riske göre kısa karşılaştırır, veriye dayalı öneri getiririm.", "S1_DISC_SJT5": "Mevcut durumu dinleyip kimlerin neye ihtiyaç duyduğunu öğrenirim.", "S1_DISC_SJT6": "Pratik çözüm seçenekleri çıkarır, küçük bir aksiyon planı yaparım.", "S1_DISC_SJT7": "Önceliklendirme yapar, net bir karar verip birini iptal ederim.", "S1_DISC_SJT8": "Kural metnini ayrıntılı okuyup hukuki dayanak ve istisnaları kontrol ederim.", "S1_DISC_SJT9": "Site kuralları/yönetmeliği kontrol edip uygun kanaldan resmi bildirim yaparım.", "S1_DISC_SJT10": "Şimdilik görmezden gelelim; uygun zamanda konuşuruz.", "S1_ERQ_REAPP1": "5", "S1_ERQ_REAPP2": "5", "S1_ERQ_REAPP3": "3", "S1_ERQ_SUPPR1": "2", "S1_ERQ_SUPPR2": "2", "S1_ERQ_SUPPR3": "1", "S1_OE_STRENGTHS": "hırslı, zeki,kolay pes etmeyen"}	Hazır mısınız? Başlayalım..\n\nGerektiğinde sivri dilli olabilirim. Dünyayı okuma biçimim, özür dilemeyen bir netliğe sahiptir. Amacım sizi daha güçlü ve daha mutlu kılmaktır; bu yüzden zaman zaman sizi sert bir şekilde eleştireceğim. Bunu sizi küçümsemek için değil, her zaman gerçeğe demirlemeniz için yapacağım.\n\n| Özellik / Boyut | Puan |\n|--------------------------------|-------|\n| **MBTI Tipi** | ENTP |\n| MBTI Dışadönüklük (E) | 60% |\n| MBTI İçedönüklük (I) | 40% |\n| MBTI Duyumsama (S) | 25% |\n| MBTI Sezgisellik (N) | 75% |\n| MBTI Düşünme (T) | 55% |\n| MBTI Hissetme (F) | 45% |\n| MBTI Yargılama (J) | 20% |\n| MBTI Algılama (P) | 80% |\n| **Big Five - Deneyime Açıklık (O)** | 56% |\n| **Big Five - Sorumluluk (C)** | 6% |\n| **Big Five - Dışadönüklük (E)** | 56% |\n| **Big Five - Uyumluluk (A)** | 56% |\n| **Big Five - Duygusal Denge (N)** | 75% |\n| **DISC - Dominantlık (D)** | 27% |\n| **DISC - Etkileyicilik (I)** | 1% |\n| **DISC - Kararlılık (S)** | 27% |\n| **DISC - Uyum (C)** | 45% |\n| Bağlanma - Kaygı | 92% |\n| Bağlanma - Kaçınma | 71% |\n| Çatışma Stili (Birincil) | Rekabetçi |\n| Duygu Düzenleme - Yeniden Değerlendirme| 83% |\n| Duygu Düzenleme - Bastırma | 17% |\n| Empati - Duygusal İlgi | 88% |\n| Empati - Perspektif Alma | 63% |\n\n## Temel Kişiliğiniz\n\nProfilinizde keskin bir ikilem göze çarpıyor: Bir yanda büyük vizyonlar kuran, zeki ve hırslı bir girişimci; diğer yanda bu vizyonları hayata geçirmek için gereken yapı ve disiplinden neredeyse tamamen yoksun bir yapı. ENTP (Tartışmacı) kişilik tipiniz, yüksek sezgisellik (N) ve algılama (P) eğilimlerinizle birleşerek sizi doğal bir "fikir makinesi" yapıyor. Yapay zeka, yaşlanmayı tersine çevirme gibi geleceğe dönük konulara olan ilginiz ve "bir ada satın alıp kendi cennetini yaratma" gibi büyük hayalleriniz bu özelliğinizin birer yansıması.\n\nAncak bu parlak zihin, gerçek dünyada ciddi bir engelle karşılaşıyor: **Sorumluluk (Conscientiousness) puanınız %6 gibi kritik derecede düşük bir seviyede.** Bu, hayatınızdaki en temel zorluğun kaynağıdır. Detayları takip etmek, organize olmak, rutin işleri sürdürmek ve başladığınız işi bitirmek sizin için olağanüstü derecede zordur. Bu durum, "işlerim kötüye gidiyor" ifadenizle ve kendi belirttiğiniz "detaylara hakim olmak" zayıflığınızla birebir örtüşüyor.\n\nDISC profilinizdeki yüksek Uyum (C) eğilimi, bu içsel çatışmayı daha da netleştiriyor. Bu, aslında kurallara uymak, sistematik ve analitik olmak *gerektiğini bildiğinizi* gösteriyor. Sorun bilmekte değil, yapmakta. Davranış testlerinde idealize ettiğiniz metodik yaklaşım, günlük hayatta kişiliğinizin temel bir parçası olan düzensizliğe yenik düşüyor.\n\nDuygusal olarak ise, %75'lik Duygusal Dengesizlik (Neuroticism) puanınız, yüksek stres ve kaygıya yatkın olduğunuzu gösteriyor. Bu durum, Bağlanma stilinizdeki %92 Kaygı ile birleştiğinde, ilişkilerde ve genel yaşamda sürekli bir endişe ve güvensizlik hali yaratıyor. Hem yakınlık arzuluyor hem de reddedilmekten ve incinmekten yoğun bir şekilde korkuyorsunuz. Bu da sizi "yalnızlık" olarak tanımladığınız mevcut duruma itiyor.\n\n## Güçlü Yönleriniz\n\n*   **Vizyoner ve Yaratıcı Zeka:** Farklı alanlardaki (yapay zeka, tropik cennetler) ilgilerinizi birleştirebilme ve geleceğe yönelik büyük resimler çizebilme yeteneğiniz en belirgin gücünüz. Yeni olasılıkları herkesten önce görür, yenilikçi çözümler hayal edersiniz. Bu, girişimcilik ruhunuzun yakıtıdır.\n\n*   **Zihinsel Çeviklik ve Hırs:** Kendinizi "hırslı" ve "kolay pes etmeyen" olarak tanımlıyorsunuz. Rekabetçi çatışma tarzınız da bunu destekliyor. Zorluklar karşısında pes etmek yerine, zihinsel olarak yeni yollar ararsınız. Duyguları yeniden değerlendirme becerinizin yüksek olması, olumsuz durumları zihinsel olarak farklı bir çerçeveye oturtmaya çalıştığınızı gösteriyor.\n\n*   **Derin Duygusal Empati:** Empati skorunuzun Duygusal İlgi boyutu oldukça yüksek. Başkalarının acısını hissedebilme kapasiteniz güçlü. Hasta kedileriniz için duyduğunuz yoğun endişe ve mutluluk ile kardeşinizin kolyesini kırdığınızda hissettiğiniz derin üzüntü, sevdiklerinize karşı ne kadar duyarlı olduğunuzun kanıtıdır. Bu, doğru koşullarda derin bağlar kurma potansiyeliniz olduğunu gösterir.\n\n*   **Bağımsızlık Ruhu:** En temel değerlerinizden biri "Özgürlük". Askerliğin bittiği gün duyduğunuz mutluluk, hayatınızdaki en güçlü motivasyonlardan birinin kısıtlamalardan kurtulmak olduğunu gösteriyor. Bu sizi kendi yolunuzu çizmeye, başkalarının kurallarına bağlı kalmadan yaşamaya iter.\n\n## Kör Noktalarınız ve Riskleriniz\n\n*   **Kronik Düzensizlik ve Yetersiz Takip:** Bu en büyük ve en tehlikeli kör noktanız. %6'lık Sorumluluk puanı, tek başına bir girişimcinin başarısız olması için yeterli bir sebeptir. Projeleri yarıda bırakma, finansal disiplinsizlik, önemli detayları gözden kaçırma ve dağınıklık, hem iş hayatınızı hem de kişisel yaşamınızı sabote eder. "Çok büyük bir şirkete sahip olma" hayali, bu temel eksiklik giderilmeden ulaşılamaz bir fantezi olarak kalmaya mahkumdur.\n\n*   **Duygusal Türbülans ve Strese Karşı Kırılganlık:** Yüksek Duygusal Dengesizlik puanınız, en küçük aksiliklerde bile ruh halinizin kolayca bozulmasına neden olur. Eleştiriyi kişisel saldırı olarak algılayabilir, belirsizlik karşısında yoğun kaygı yaşayabilirsiniz. Bu durum, mantıklı kararlar almanızı zorlaştırır ve sizi sürekli bir "savaş ya da kaç" modunda tutarak enerjinizi tüketir.\n\n*   **Korkulu-Kaçınmacı Bağlanma ve Sosyal İzolasyon:** Hem yüksek kaygı hem de yüksek kaçınma, ilişkilerde bir "gel-git" dinamiği yaratır. Bir yandan "güven, uyum, destek" gibi derin bir özlem duyarken, diğer yandan biri size yaklaştığında boğulma veya incinme korkusuyla geri çekilirsiniz. Bu, sizi bir yalnızlık döngüsüne hapseder. "Arkadaşlarla sohbet" etmeyi sevdiğinizi ama "şu an arkadaşınız olmadığını" söylemeniz bu durumun somut bir özetidir.\n\n*   **Entelektüel Kibir ve Sabırsızlık:** "Aptal insanlarla muhatap olmak" ve "özgüvenli cehalet" gibi durumlara tahammül edememeniz, zekanıza güvendiğinizi gösterse de, aynı zamanda sizi iş birliğine kapalı ve sabırsız yapabilir. İnsanlar üzerinde etki yaratmakta zorlandığınızı belirtmeniz, bu tutumun başkalarını sizden uzaklaştırdığının bir işareti olabilir.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişki dünyanız, çocuklukta babanızla yaşadığınız travmatik deneyimin gölgesinde şekillenmiş görünüyor. O gün ormanda hissettiğiniz "çaresizlik, nefret, gururun kırılması ve eve gitmek istememe" duyguları, muhtemelen bugün yakın ilişkilere dair bilinçaltı kodlarınızı oluşturuyor. "Güven" sizin için birincil ihtiyaç, çünkü en çok güvenmeniz gereken kişi tarafından fiziksel ve duygusal şiddete maruz kalmışsınız.\n\nBu, "Korkulu-Kaçınmacı" bağlanma stilini doğurur. Bu stile sahip kişiler, bir yandan sevgi ve kabul görmeyi çok isterler (yüksek kaygı), diğer yandan da yakınlığın tehlikeli ve acı verici olabileceğine dair derin bir inanç taşırlar (yüksek kaçınma). Bu durum, potansiyel partnerleri hem kendinize çekmenize hem de tam bağlanma noktasında onları itmenize neden olur. Sınırlarınız ("yalan, aldatma, saygısızlık") son derece nettir, çünkü bu davranışlar geçmişteki yaralarınızı yeniden kanatır.\n\nBir ilişkiden beklentiniz "hayatınıza renk getirmesi ve desteklenmek". Ancak mevcut yapınızla, bir partnerin bu rolü üstlenmesi zordur. Önce sizin kendi içsel istikrarınızı sağlamanız ve bir başkasının sizi "tamamlamasını" beklemek yerine, kendi başınıza "bütün" olmayı öğrenmeniz gerekir.\n\n## Kariyer ve Çalışma Tarzınız\n\nGirişimci olmanız tesadüf değil; bu, ENTP profilinizin ve özgürlük ihtiyacınızın doğal bir sonucudur. Ancak "girişimci" ve "başarılı girişimci" arasında dev bir fark vardır ve bu farkın adı **sorumluluktur**.\n\n**Çalışma stilinizdeki paradoks şudur:** Fikir üretme, strateji kurma, pazardaki boşlukları görme ve insanları bir vizyona heyecanlandırma konusunda muhtemelen harikasınız. Ancak iş operasyonel yönetime, finansal takibe, proje planlamasına ve sıkıcı evrak işlerine geldiğinde tamamen etkisiz kalıyorsunuz.\n\nBu yapıdaki birinin tek başına bir işi yürütmesi neredeyse imkansızdır. Başarısızlık kaçınılmazdır. Sizin için tek bir çıkış yolu var: **Yapısal olarak eksik olduğunuz alanları dolduracak bir ortak veya kilit bir çalışan bulmak.** Sizin vizyonunuzu alıp onu adım adım hayata geçirecek, son derece organize, detaycı ve güvenilir bir "operasyon yöneticisine" (COO) ihtiyacınız var. Siz "ne" yapılacağını söylersiniz, o ise "nasıl" yapılacağını planlar ve takip eder. Bu olmadan, işlerinizin kötüye gitmesi devam edecektir.\n\nLiderlik vasıflarınızdaki zayıflık, sabırsızlığınızdan ve insan yönetimi yerine fikir yönetimine odaklanmanızdan kaynaklanıyor. DISC'teki sıfıra yakın Etkileyicilik (I) puanınız, insanları ikna etme ve onlara ilham verme konusunda doğal bir yeteneğiniz olmadığını, bunu bilinçli olarak geliştirmeniz gerektiğini gösteriyor.\n\n## Duygusal Düzeniniz ve Stresle Başa Çıkma\n\nDuygusal termostatınız hassas ayarda. Yüksek Duygusal Dengesizlik, dünyayı potansiyel bir tehdit alanı olarak algılamanıza neden olur. İşlerin kötüye gitmesi, yalnızlık hissi veya ait olamama duygusu gibi stres faktörleri, sisteminizde hızla alarm zillerini çaldırır.\n\nBaşa çıkma mekanizmanız, "beni rahat hissettirecek yaşamların olduğu film veya diziler izlemek" olarak tanımladığınız **kaçıştır**. Bu, acı veren gerçeklikten geçici bir mola almanızı sağlar. Ancak bu bir çözüm değil, bir uyuşturucudur. Gerçek sorunlar (başarısız iş, sosyal izolasyon) siz dizi izlerken büyümeye devam eder. Bu strateji, sizi eylemsizliğe iterek sorunlarınızı derinleştirir.\n\nTetikleyicileriniz ("özgüvenli cehalet, saygısızlık, ısrar") genellikle kontrolü kaybetme veya yetkinliğinizin sorgulanması hissine dayanır. Bu durumlar, çocuklukta yaşadığınız çaresizlik anılarını tetikleyerek orantısız bir öfke veya savunma mekanizması ortaya çıkarabilir.\n\n## Hayat Döngünüz ve Olası Tuzaklar\n\nMevcut gidişatla, hayatınızın bir dizi parlak başlangıç ve hayal kırıklığı yaratan sonuçlardan oluşması muhtemeldir. Heyecan verici bir iş fikri bulur, başlarsınız ama detaylarda boğulup pes edersiniz. Biriyle tanışır, heyecanlanırsınız ama yakınlık arttıkça kaygılarınız devreye girer ve ilişkiyi sabote edersiniz.\n\n"Bir ada satın alıp kendi cennetini yaratma" hayali, bu döngüden bir kaçış fantezisidir. Bu, karmaşık ve hayal kırıklığı yaratan insan ilişkilerinden ve başarısızlık riskinden arınmış, tamamen sizin kontrolünüzde olan bir dünya arzusudur. Ancak bu, bir hedef değil, bir semptomdur. Yalnızlığınızı ve içsel boşluğunuzu bir ada dolduramaz.\n\nEn büyük tuzak, dışsal bir başarının (büyük bir şirket, zenginlik) içsel sorunlarınızı (yalnızlık, kaygı, aidiyetsizlik) çözeceğine inanmaktır. Çözüm dışarıda değil, içeride.\n\n## Eyleme Geçirilebilir İleriye Dönük Yol Haritası\n\n1.  **Hemen Bir "Operasyon Ortağı" Bulun:** Bu bir tavsiye değil, bir zorunluluktur. Sizin tam zıttınız olan, detaycı, organize, takıntılı derecede düzenli bir iş ortağı veya üst düzey bir çalışan bulun. Bu, işinizi kurtarmak için atmanız gereken ilk ve en önemli adımdır. Vizyon sizden, icraat ondan gelmeli.\n\n2.  **İrade Gücüne Değil, Sistemlere Güvenin:** Düzensizliğinizin bir karakter zafiyeti olmadığını, kişiliğinizin bir parçası olduğunu kabul edin. Onu değiştirmeye çalışmak yerine, etrafından dolaşacak sistemler kurun. Proje yönetim yazılımları (Trello, Asana), otomatik hatırlatıcılar, haftalık sabit muhasebeci toplantıları gibi dışsal yapılar oluşturun.\n\n3.  **Travmayı Profesyonelce Ele Alın:** Babanızla yaşadığınız deneyim, bugünkü bağlanma sorunlarınızın ve güvensizliğinizin temelidir. Bu konuyla yüzleşmek için EMDR veya Şema Terapi gibi travma odaklı terapiler konusunda uzman bir terapistten destek almayı ciddi olarak düşünün. Bu, ilişkisel geleceğiniz için yapabileceğiniz en büyük yatırımdır.\n\n4.  **"Güvenli" Sosyalleşme Adımları Atın:** Sosyal kaslarınız zayıflamış. Yüksek basınçlı flört ortamları yerine, ilgi alanlarınıza yönelik düşük riskli ortamlara girin. Bir yapay zeka topluluğuna, bir teknoloji seminerine katılın. Amaç romantik bir ilişki bulmak değil, sadece insanlarla ortak bir zemin üzerinde sohbet etme pratiği yapmak olmalı.\n\n5.  **"Başarıyı" Yeniden Tanımlayın:** "Ada satın almak" gibi soyut ve devasa bir hedef yerine, başarının sizin için bir hafta içinde ne anlama geldiğini tanımlayın. Belki de "kârlı bir hafta geçirmek ve bir arkadaşla kahve içmek" demektir. Hedeflerinizi ulaşılabilir ve somut hale getirin.\n\n6.  **Kaçış Yerine Eyleme Yönelin:** Bir film veya diziye sığınma dürtüsü geldiğinde, kendinize meydan okuyun. Sadece 15 dakikalığına işinizle ilgili küçük bir görevi tamamlayın, uzun zamandır aramadığınız bir akrabanızı arayın veya sadece dışarı çıkıp yürüyün. Kaçış döngüsünü küçük eylemlerle kırın.\n\n7.  **Sınır İletişimi Pratiği Yapın:** Sınırlarınızın ne olduğunu biliyorsunuz. Şimdi pratik yapmanız gereken şey, bu sınırlar aşıldığında öfke biriktirip patlamak yerine, o anda sakin ve net bir şekilde "Bu davranışın bana saygısızlık olduğunu düşünüyorum ve devam etmesini istemiyorum" diyebilmektir.\n\n8.  **"Yeterince İyi" Prensibini Benimseyin:** Mükemmeliyetçilik, eylemsizliğin en şık kılıfıdır. Projelerinizde "mükemmeli" hedeflemek yerine "işe yarar ve yeterince iyi olanı" hedefleyin. İlk versiyonu çıkarın, sonra geliştirirsiniz. Bu, başlama ve bitirme konusundaki en büyük engelinizle savaşmanıza yardımcı olacaktır.\n\n## Kendi Kelimelerinizle: Anılar ve Anlam\n\nYazdıklarınız, test sonuçlarının ötesinde, ruhunuzun bir haritasını sunuyor.\n\nEn mutlu anılarınızda iki tema öne çıkıyor: **Özgürlük ve Kavuşma.** Askerlikten sonra "özgür olacak olmak" ve hasta kedilerinize "12 gün sonra" kavuşmak. Bu, hayatınızdaki temel gerilimi gösteriyor: Bir yandan kısıtlamalardan kaçma arzusu, diğer yandan kaygılı bir ayrılıktan sonra sevilen bir varlıkla yeniden bağ kurma ihtiyacı. Değerlerinizdeki "Özgürlük" ve bağlanma testinizdeki "Yüksek Kaygı" burada ete kemiğe bürünüyor.\n\nEn zor anılarınız ise **Çaresizlik, Utanç ve Ayrılık** temalarını işliyor. Abinizin kolyesini kırdığınızdaki suçluluk, babanız tarafından dövüldüğünüzdeki "çaresizlik, nefret ve eve gitmek istememe" ve abinizin askere gidişindeki ayrılık acısı... Özellikle babanızla yaşadığınız olay, dünyanın güvenilmez bir yer olduğu ve en yakınlarınızın bile size zarar verebileceği yönündeki temel inancınızı şekillendirmiş. Bugün insanlara güvenmekte zorlanmanızın ve yalnız kalmanızın kökeni bu anıda saklı.\n\nHedefleriniz ve gerçekliğiniz arasındaki uçurum da çok net: Bir yanda "çok büyük bir şirkete sahip olmak" hedefi, diğer yanda "işlerim kötüye gidiyor" gerçeği. Bir yanda "insanlar üzerinde daha yüksek etki" yaratma isteği, diğer yanda "sosyal yeteneklerimin" zayıf olduğunu kabul etme. Bu, hayallerinizle mevcut yetenekleriniz ve kişisel yapınız arasında dev bir boşluk olduğunu gösteriyor. Bu raporun amacı, bu boşluğu kapatmak için size bir köprü inşa etmenize yardımcı olmaktır.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, psikolojide kabul görmüş üç farklı modelin birleşimine dayanmaktadır. Her biri, kişiliğinizin farklı bir katmanını aydınlatır.\n\n**Beş Faktör Kişilik Kuramı (Big Five)**, kişiliğinizin biyolojik temellere dayanan temel ve istikrarlı özelliklerini ölçer. Sizin durumunuzda, **düşük Sorumluluk (Conscientiousness)** ve **yüksek Duygusal Dengesizlik (Neuroticism)** en belirleyici bulgulardır. Bilimsel araştırmalar, bu kombinasyonun iş hayatında başarısızlık, ilişki istikrarsızlığı ve genel yaşam doyumunda düşüklük için güçlü bir risk faktörü olduğunu defalarca göstermiştir. Bu, bir fikir değil, istatistiksel bir gerçektir.\n\n**MBTI (Myers-Briggs Tipi Göstergesi)**, bu temel özelliklerin üzerine, dünyayı nasıl algıladığınızı ve kararlarınızı nasıl verdiğinizi gösteren bir bilişsel tercih modelidir. ENTP profiliniz, neden harika fikirler ürettiğinizi (Sezgisellik) ama bunları hayata geçirmekte zorlandığınızı (Algılama) açıklar. Bu, "ne" sorusuna odaklanıp "nasıl" sorusunu ihmal etme eğiliminizi ortaya koyar.\n\n**DISC modeli** ise durumsal davranışlarınızı, özellikle iş ve takım ortamlarındaki eğilimlerinizi haritalandırır. Sizin DISC profilinizdeki ilginç bulgu, idealize ettiğiniz davranışlar (yüksek Uyum/C - metodik, analitik olma) ile gerçekteki eğilimleriniz (düşük Sorumluluk/C - düzensiz, spontane olma) arasındaki çatışmadır. Bu, sürekli bir içsel sürtünmeye neden olur; ne yapmanız gerektiğini bilirsiniz ama kişiliğiniz buna direnir.\n\nBu üç model bir araya geldiğinde, tutarlı ve çok yönlü bir portre ortaya çıkıyor: Vizyonu olan ancak uygulamada zorlanan, duygusal olarak dalgalı, bağlantı kurmayı arzulayan ama korkan zeki bir birey. Tahminlerimiz ve tavsiyelerimiz, bu kanıta dayalı çerçevelerden yola çıkarak, sizin özel durumunuza uyarlanmıştır. Unutmayın, kişilik değişmez değildir ama davranışlar ve sistemler değiştirilebilir. Güç, bu farkı anlamakta yatar.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilendirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-20 23:33:45.146712+03	2025-08-20 23:35:39.303987+03	{"language": "tr", "language_ok": true}
\.


--
-- Data for Name: assessments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.assessments (id, person_id, type, version, created_at) FROM stdin;
\.


--
-- Data for Name: chat_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_sessions (id, dyad_id, metadata) FROM stdin;
\.


--
-- Data for Name: dyad_scores; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dyad_scores (id, dyad_id, compatibility_score, strengths_json, risks_json, plan_json, confidence) FROM stdin;
\.


--
-- Data for Name: dyads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dyads (id, a_person_id, b_person_id, relation_type) FROM stdin;
\.


--
-- Data for Name: iap_products; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.iap_products (id, platform, product_id, product_type, plan_id, service_type, is_active, created_at) FROM stdin;
44e15519-2269-4d48-8519-bbab8d718451	ios	com.personax.standard.monthly	subscription	standard	\N	t	2025-08-19 22:28:08.519604
5c448ccf-8829-410e-8fe6-aaa8b74ded55	ios	com.personax.extra.monthly	subscription	extra	\N	t	2025-08-19 22:28:08.519604
8f40f1af-a04c-444e-8d07-1380903571ce	android	standard_monthly	subscription	standard	\N	t	2025-08-19 22:28:08.519604
02343cec-1450-4404-aeda-c57b1f8c5d4d	android	extra_monthly	subscription	extra	\N	t	2025-08-19 22:28:08.519604
9d8f1565-0495-4192-829b-93a2ae985eb1	ios	com.personax.self.analysis	consumable	\N	self_analysis	t	2025-08-19 22:28:08.520252
bd765436-af31-4e08-8f83-b045c296bb6a	ios	com.personax.other.analysis	consumable	\N	other_analysis	t	2025-08-19 22:28:08.520252
079053a0-6885-49e5-aa69-04be01a00fe3	ios	com.personax.relationship.analysis	consumable	\N	relationship_analysis	t	2025-08-19 22:28:08.520252
1e642dab-a33d-45cb-8e3f-994185d6bfa5	android	self_analysis	consumable	\N	self_analysis	t	2025-08-19 22:28:08.520252
219ab5da-9adc-4911-be60-6bd55cb3e806	android	other_analysis	consumable	\N	other_analysis	t	2025-08-19 22:28:08.520252
e5a1dcd4-6b9d-49d4-9171-e28e80a78e8c	android	relationship_analysis	consumable	\N	relationship_analysis	t	2025-08-19 22:28:08.520252
\.


--
-- Data for Name: iap_purchases; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.iap_purchases (id, user_id, platform, product_id, transaction_id, receipt_data, validation_status, validation_response, created_at, validated_at) FROM stdin;
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.items (id, form, section, subscale, text_tr, type, options_tr, reverse_scored, scoring_key, weight, notes, display_order, test_type) FROM stdin;
S1_MB_FC1	S1_self	MBTI	EI	A) Kalabalıkta enerji toplarım  |  B) Yalnız kalarak şarj olurum	ForcedChoice2	A|B	0	{"A":"EI:E","B":"EI:I"}	1	Ipsatif (sosyal beğenirlik azaltma)	\N	MBTI
S1_MB_FC2	S1_self	MBTI	EI	A) Yeni insanlarla hızla bağ kurarım  |  B) Önce gözlemler sonra açılırım	ForcedChoice2	A|B	0	{"A":"EI:E","B":"EI:I"}	1	\N	\N	MBTI
S1_MB_FC3	S1_self	MBTI	EI	A) Yüksek sesli ve hareketli ortamlar beni canlandırır  |  B) Sessiz ve sakin ortamları tercih ederim	ForcedChoice2	A|B	0	{"A":"EI:E","B":"EI:I"}	1	\N	\N	MBTI
S1_MB_FC4	S1_self	MBTI	SN	A) Gerçekler ve kanıtlar  |  B) Fikirler ve olasılıklar beni daha çok cezbeder	ForcedChoice2	A|B	0	{"A":"SN:S","B":"SN:N"}	1	\N	\N	MBTI
S1_MB_FC5	S1_self	MBTI	SN	A) Detaylara odaklanırım  |  B) Büyük resmi görmeyi tercih ederim	ForcedChoice2	A|B	0	{"A":"SN:S","B":"SN:N"}	1	\N	\N	MBTI
S1_MB_FC6	S1_self	MBTI	SN	A) Mevcut duruma dayanırım  |  B) Gelecekteki potansiyeli merak ederim	ForcedChoice2	A|B	0	{"A":"SN:S","B":"SN:N"}	1	\N	\N	MBTI
S1_MB_FC7	S1_self	MBTI	TF	A) Kararda tutarlılık ve mantık  |  B) Etki ve duygular önceliklidir	ForcedChoice2	A|B	0	{"A":"TF:T","B":"TF:F"}	1	\N	\N	MBTI
S1_MB_FC8	S1_self	MBTI	TF	A) Doğrudan geri bildirim veririm  |  B) İncitmemek için dili yumuşatırım	ForcedChoice2	A|B	0	{"A":"TF:T","B":"TF:F"}	1	\N	\N	MBTI
S1_MB_FC9	S1_self	MBTI	TF	A) Adalet ve ilke  |  B) İlişki ve uyum önce gelir	ForcedChoice2	A|B	0	{"A":"TF:T","B":"TF:F"}	1	\N	\N	MBTI
S1_MB_FC10	S1_self	MBTI	JP	A) Plan ve takvim isterim  |  B) Esnek kalmayı severim	ForcedChoice2	A|B	0	{"A":"JP:J","B":"JP:P"}	1	\N	\N	MBTI
S1_MB_FC11	S1_self	MBTI	JP	A) Kararı hızlıca kapatırım  |  B) Seçenekleri bir süre açık tutarım	ForcedChoice2	A|B	0	{"A":"JP:J","B":"JP:P"}	1	\N	\N	MBTI
S1_MB_FC12	S1_self	MBTI	JP	A) Belirsizlik rahatsız eder  |  B) Akışına bırakabilirim	ForcedChoice2	A|B	0	{"A":"JP:J","B":"JP:P"}	1	\N	\N	MBTI
S1_AT_ANX1	S1_self	Attachment	ANX	Partnerim geç yanıt verdiğinde huzursuz olurum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	ECR-R esinli	\N	ATTACHMENT
S1_AT_ANX2	S1_self	Attachment	ANX	İlişkide sık sık güvence ihtiyacı hissederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S1_AT_ANX3	S1_self	Attachment	ANX	Terk edilme korkusu zaman zaman aklıma gelir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S1_AT_ANX4	S1_self	Attachment	ANX	Partnerimin sevgisini kanıtlamasına sık ihtiyaç duyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S1_AT_ANX5	S1_self	Attachment	ANX	İlişkiyle ilgili olumsuz senaryoları zihnimde canlandırırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S1_AT_ANX6	S1_self	Attachment	ANX	Partnerimle aram bozulduğunda hızla paniğe kapılırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S1_AT_AVO1	S1_self	Attachment	AVO	Duygularımı paylaşmakta zorlanırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S1_TKI_1	S1_self	Conflict	COMPETE	Evde ortak alanın dağınıklığı konusunda anlaşmazlık var; ilk eğiliminiz?	MultiChoice5	Bugünden itibaren net kurallar koyarım; uymayana açıkça uyarı yaparım.|Beraber kısa bir toplantı yapıp kural + görev paylaşımı oluşturmayı öneririm.|"Bu hafta ben, gelecek hafta siz" gibi orta yol teklif ederim.|Şimdilik açmam; uygun bir zamanda sakinleşince konuşmak isterim.|Sorun etmeyip ben toparlarım; siz nasıl rahatsanız öyle olsun.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	Günlük yaşam SJT	\N	CONFLICT_STYLE
S1_TKI_4	S1_self	Conflict	AVOID	Kalabalıkta biri sıranızı kesti; tepkiniz?	MultiChoice5	Netçe uyarır, yerime dönmesini isterim.|Çevreyle birlikte sırayı düzenleyelim, kibarca kuralı hatırlatırım.|Aceleyse bu kez geçmesine izin verelim; sırayı birlikte netleştirelim.|Tartışmaya girmem; görmezden gelirim.|Rahatsız olsam da sıramı veririm, mesele büyümesin.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	\N	\N	CONFLICT_STYLE
S1_ERQ_REAPP1	S1_self	EmotionReg	REAPP	Olumsuz bir olayı kafamda yeniden çerçevelemeye çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	ERQ (yeniden değerlendirme) esinli	\N	EMOTION_REGULATION
S1_ERQ_REAPP2	S1_self	EmotionReg	REAPP	Zor bir durumda durumu farklı bakış açılarından görmeye çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	EMOTION_REGULATION
S1_ERQ_SUPPR1	S1_self	EmotionReg	SUPPR	Duygularımı dışa yansıtmamayı tercih ederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	ERQ (bastırma) esinli	\N	EMOTION_REGULATION
S1_ERQ_SUPPR2	S1_self	EmotionReg	SUPPR	Üzgün olsam bile yüzüme yansıtmam.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	EMOTION_REGULATION
S1_ERQ_SUPPR3	S1_self	EmotionReg	SUPPR	Toplum içinde duygusal tepkilerimi bastırırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	EMOTION_REGULATION
S1_EMP_PT1	S1_self	Empathy	PT	Birinin bakış açısını anlamak için aktif çaba gösteririm.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	IRI esinli	\N	EMPATHY
S1_EMP_PT2	S1_self	Empathy	PT	Tartışmada karşı tarafın gerekçelerini anlamaya çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	EMPATHY
S1_EMP_EC1	S1_self	Empathy	EC	Başkalarının acısı beni duygusal olarak etkiler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	EMPATHY
S1_EMP_EC2	S1_self	Empathy	EC	Zor durumda olanlara karşı şefkat hissederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	EMPATHY
S1_OE_HAPPY	S1_self	LifeStory	OpenEnded	En mutlu anılarınızdan 1–3 tanesini yazınız (her biri ayrı paragraf).	OpenText		0	\N	1	Opsiyonel	\N	LIFE_STORY
S1_OE_HARD	S1_self	LifeStory	OpenEnded	En zor/kötü anılarınızdan 1–3 tanesini yazınız (her biri ayrı paragraf).	OpenText		0	\N	1	Opsiyonel; travmatik detay şart değil	\N	LIFE_STORY
S1_Q_CONS	S1_self	Quality	CONS	Bu testte dürüst cevap verdiğime inanıyorum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S1_Q_SPEED	S1_self	Quality	SPEED	Soruları acele etmeden yanıtladım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	RT kalite ile birlikte kullanın	\N	QUALITY_CHECK
S1_Q_REPEAT	S1_self	Quality	REPEAT	Benzer sorulara farklı cevap verdiğimi düşünüyorum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	Tutarlılık	\N	QUALITY_CHECK
S1_Q_ATTN	S1_self	Quality	IMC	Dikkat kontrolü: Lütfen bu madde için 'Katılıyorum' yani 4 nolu seçeneğini işaretleyiniz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	{"target":"Katılıyorum"}	1	Instructional Manipulation Check	\N	QUALITY_CHECK
S1_OE_STRENGTHS	S1_self	OpenEnded	OE	Kendinizde en güçlü bulduğunuz 3 özelliği yazınız.	OpenText		0	\N	1	\N	\N	OPEN_ENDED
S1_OE_WEAK	S1_self	OpenEnded	OE	Geliştirmek istediğiniz 3 alanı yazınız.	OpenText		0	\N	1	\N	\N	OPEN_ENDED
S2R_mother_EI1	S2R_mother	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mother_EI2	S2R_mother	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mother_SN1	S2R_mother	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mother_SN2	S2R_mother	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mother_COM1	S2R_mother	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mother_COL1	S2R_mother	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mother_CRM1	S2R_mother	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mother_AVD1	S2R_mother	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mother_ACM1	S2R_mother	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mother_COL2	S2R_mother	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mother_VAL1	S2R_mother	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mother_VAL2	S2R_mother	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mother_VAL3	S2R_mother	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mother_VAL4	S2R_mother	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_sibling_VAL3	S2R_sibling	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mother_CLOSE1	S2R_mother	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_mother_CLOSE2	S2R_mother	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_mother_CLOSE3	S2R_mother	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_mother_CLOSE4	S2R_mother	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_mother_VIG1	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_father_EI1	S2R_father	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_father_EI2	S2R_father	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_father_SN1	S2R_father	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_father_SN2	S2R_father	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_father_TF1	S2R_father	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_father_TF2	S2R_father	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_father_COM1	S2R_father	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_father_COL1	S2R_father	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_father_CRM1	S2R_father	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_father_AVD1	S2R_father	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_father_ACM1	S2R_father	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_father_COL2	S2R_father	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_father_VAL1	S2R_father	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_father_VAL2	S2R_father	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_father_VAL3	S2R_father	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_father_VAL4	S2R_father	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_father_CLOSE1	S2R_father	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_father_CLOSE2	S2R_father	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_father_CLOSE3	S2R_father	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_father_CLOSE4	S2R_father	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_mother_CONF1	S2R_mother	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_mother_FREQ1	S2R_mother	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_mother_VIG4	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_father_VIG1	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_sibling_EI1	S2R_sibling	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_sibling_EI2	S2R_sibling	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_sibling_SN1	S2R_sibling	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_sibling_SN2	S2R_sibling	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_sibling_TF1	S2R_sibling	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_sibling_COM1	S2R_sibling	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_sibling_COL1	S2R_sibling	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_sibling_CRM1	S2R_sibling	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_sibling_AVD1	S2R_sibling	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_sibling_ACM1	S2R_sibling	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_sibling_COL2	S2R_sibling	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_sibling_VAL1	S2R_sibling	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_sibling_VAL2	S2R_sibling	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_sibling_CLOSE1	S2R_sibling	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_sibling_CLOSE2	S2R_sibling	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_sibling_CLOSE3	S2R_sibling	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_sibling_CLOSE4	S2R_sibling	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_father_CONF1	S2R_father	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_father_FREQ1	S2R_father	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_father_VIG2	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_father_VIG3	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_relative_EI1	S2R_relative	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_relative_EI2	S2R_relative	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_relative_SN1	S2R_relative	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_relative_SN2	S2R_relative	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_relative_TF1	S2R_relative	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_relative_TF2	S2R_relative	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_relative_COM1	S2R_relative	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_relative_COL1	S2R_relative	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_relative_CRM1	S2R_relative	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_relative_AVD1	S2R_relative	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_relative_ACM1	S2R_relative	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_relative_COL2	S2R_relative	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_sibling_VAL4	S2R_sibling	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_relative_CLOSE1	S2R_relative	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_relative_CLOSE2	S2R_relative	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_sibling_CONF1	S2R_sibling	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_sibling_FREQ1	S2R_sibling	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_sibling_VIG1	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_sibling_VIG2	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_sibling_VIG3	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_best_friend_EI1	S2R_best_friend	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_best_friend_EI2	S2R_best_friend	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_best_friend_SN1	S2R_best_friend	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_best_friend_SN2	S2R_best_friend	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_best_friend_TF1	S2R_best_friend	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_best_friend_TF2	S2R_best_friend	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_best_friend_COM1	S2R_best_friend	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_best_friend_COL1	S2R_best_friend	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_best_friend_CRM1	S2R_best_friend	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_relative_VAL1	S2R_relative	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_relative_VAL2	S2R_relative	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_relative_VAL3	S2R_relative	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_relative_VAL4	S2R_relative	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_relative_CLOSE3	S2R_relative	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_relative_CLOSE4	S2R_relative	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	RELATIONSHIP
S2R_relative_CONF1	S2R_relative	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_relative_FREQ1	S2R_relative	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_relative_VIG1	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_friend_EI1	S2R_friend	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_friend_EI2	S2R_friend	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_friend_SN1	S2R_friend	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_friend_SN2	S2R_friend	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_friend_TF1	S2R_friend	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_friend_TF2	S2R_friend	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_best_friend_AVD1	S2R_best_friend	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_best_friend_ACM1	S2R_best_friend	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_best_friend_COL2	S2R_best_friend	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_best_friend_VAL1	S2R_best_friend	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_best_friend_VAL2	S2R_best_friend	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_best_friend_VAL3	S2R_best_friend	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_best_friend_VAL4	S2R_best_friend	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_best_friend_CONF1	S2R_best_friend	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_best_friend_FREQ1	S2R_best_friend	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_best_friend_AVAIL1	S2R_best_friend	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_best_friend_AVAIL2	S2R_best_friend	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_best_friend_AVAIL3	S2R_best_friend	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_best_friend_VIG1	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_best_friend_VIG2	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_friend_JP1	S2R_friend	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_friend_JP2	S2R_friend	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_roommate_EI1	S2R_roommate	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_roommate_EI2	S2R_roommate	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_friend_COM1	S2R_friend	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_friend_COL1	S2R_friend	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_friend_CRM1	S2R_friend	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_friend_AVD1	S2R_friend	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_friend_ACM1	S2R_friend	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_friend_VAL1	S2R_friend	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_friend_VAL2	S2R_friend	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_friend_VAL3	S2R_friend	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_friend_VAL4	S2R_friend	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_friend_CONF1	S2R_friend	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_friend_FREQ1	S2R_friend	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_friend_AVAIL1	S2R_friend	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_friend_AVAIL2	S2R_friend	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_friend_AVAIL3	S2R_friend	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_friend_AVAIL4	S2R_friend	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_friend_VIG1	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_friend_VIG2	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_roommate_SN1	S2R_roommate	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_roommate_SN2	S2R_roommate	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_roommate_TF1	S2R_roommate	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_roommate_COM1	S2R_roommate	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_roommate_COL1	S2R_roommate	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_roommate_CRM1	S2R_roommate	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_roommate_AVD1	S2R_roommate	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_roommate_ACM1	S2R_roommate	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_roommate_VAL1	S2R_roommate	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_roommate_VAL2	S2R_roommate	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_roommate_VAL3	S2R_roommate	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_roommate_VAL4	S2R_roommate	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_roommate_CONF1	S2R_roommate	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_roommate_FREQ1	S2R_roommate	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_roommate_AVAIL1	S2R_roommate	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_roommate_AVAIL2	S2R_roommate	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_roommate_AVAIL3	S2R_roommate	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_roommate_AVAIL4	S2R_roommate	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_roommate_VIG1	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_roommate_VIG2	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_roommate_VIG3	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_neighbor_EI1	S2R_neighbor	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_neighbor_EI2	S2R_neighbor	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_neighbor_SN1	S2R_neighbor	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_neighbor_COM1	S2R_neighbor	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_neighbor_COL1	S2R_neighbor	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_neighbor_CRM1	S2R_neighbor	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_neighbor_AVD1	S2R_neighbor	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_neighbor_ACM1	S2R_neighbor	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_neighbor_COL2	S2R_neighbor	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_neighbor_VAL1	S2R_neighbor	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_neighbor_VAL2	S2R_neighbor	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_neighbor_VAL3	S2R_neighbor	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_neighbor_VAL4	S2R_neighbor	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_neighbor_AVAIL1	S2R_neighbor	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_neighbor_AVAIL2	S2R_neighbor	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_neighbor_AVAIL3	S2R_neighbor	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_neighbor_VIG1	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_neighbor_VIG2	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_neighbor_VIG3	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_crush_EI1	S2R_crush	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_crush_EI2	S2R_crush	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_crush_SN1	S2R_crush	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_crush_SN2	S2R_crush	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_crush_TF1	S2R_crush	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_crush_TF2	S2R_crush	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_crush_ANX1	S2R_crush	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_crush_ANX2	S2R_crush	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_crush_AVO1	S2R_crush	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_crush_AVO2	S2R_crush	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_crush_COM1	S2R_crush	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_crush_COL1	S2R_crush	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_crush_CRM1	S2R_crush	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_crush_VAL1	S2R_crush	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_crush_VAL2	S2R_crush	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_crush_VAL3	S2R_crush	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_crush_VAL4	S2R_crush	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_neighbor_CONF1	S2R_neighbor	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_neighbor_FREQ1	S2R_neighbor	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_crush_VIG1	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_crush_VIG2	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_date_EI1	S2R_date	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_date_EI2	S2R_date	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_date_SN1	S2R_date	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_date_SN2	S2R_date	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_date_TF1	S2R_date	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_date_ANX1	S2R_date	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_date_ANX2	S2R_date	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_date_AVO1	S2R_date	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_date_AVO2	S2R_date	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_date_COM1	S2R_date	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_date_COL1	S2R_date	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_date_CRM1	S2R_date	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_date_VAL1	S2R_date	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_date_VAL2	S2R_date	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_date_VAL3	S2R_date	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_date_VAL4	S2R_date	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mentee_PRO1	S2R_mentee	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_crush_CONF1	S2R_crush	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_crush_FREQ1	S2R_crush	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_crush_VIG3	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_partner_EI1	S2R_partner	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_partner_EI2	S2R_partner	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_partner_SN1	S2R_partner	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_partner_SN2	S2R_partner	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_partner_TF1	S2R_partner	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_partner_ANX1	S2R_partner	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_partner_ANX2	S2R_partner	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_partner_AVO1	S2R_partner	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_partner_AVO2	S2R_partner	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_partner_COM1	S2R_partner	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_partner_COL1	S2R_partner	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_partner_CRM1	S2R_partner	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_date_CONF1	S2R_date	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_date_FREQ1	S2R_date	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_date_VIG1	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_date_VIG2	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_date_VIG3	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_date_VIG4	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_fiance_EI1	S2R_fiance	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_fiance_EI2	S2R_fiance	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_fiance_SN1	S2R_fiance	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_fiance_SN2	S2R_fiance	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_fiance_TF1	S2R_fiance	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_fiance_TF2	S2R_fiance	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_fiance_COM1	S2R_fiance	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_fiance_COL1	S2R_fiance	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_fiance_CRM1	S2R_fiance	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_fiance_AVD1	S2R_fiance	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_fiance_ACM1	S2R_fiance	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_fiance_COL2	S2R_fiance	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_partner_VAL1	S2R_partner	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_partner_VAL2	S2R_partner	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_partner_VAL3	S2R_partner	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_partner_VAL4	S2R_partner	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_partner_CONF1	S2R_partner	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_partner_FREQ1	S2R_partner	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_partner_VIG1	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_partner_VIG2	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_spouse_EI1	S2R_spouse	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_spouse_EI2	S2R_spouse	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_spouse_SN1	S2R_spouse	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_spouse_SN2	S2R_spouse	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_spouse_TF1	S2R_spouse	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_spouse_TF2	S2R_spouse	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_fiance_ANX1	S2R_fiance	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_fiance_ANX2	S2R_fiance	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_fiance_AVO1	S2R_fiance	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_fiance_AVO2	S2R_fiance	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_spouse_COM1	S2R_spouse	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_spouse_COL1	S2R_spouse	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_fiance_VAL1	S2R_fiance	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_fiance_VAL2	S2R_fiance	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_fiance_VAL3	S2R_fiance	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_fiance_VAL4	S2R_fiance	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_fiance_CONF1	S2R_fiance	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_fiance_FREQ1	S2R_fiance	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_fiance_VIG1	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_fiance_VIG2	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_fiance_VIG3	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_coworker_EI1	S2R_coworker	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_coworker_EI2	S2R_coworker	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_coworker_SN1	S2R_coworker	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_coworker_SN2	S2R_coworker	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_coworker_TF1	S2R_coworker	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_spouse_ANX1	S2R_spouse	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_spouse_ANX2	S2R_spouse	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_spouse_AVO1	S2R_spouse	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_spouse_AVO2	S2R_spouse	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S2R_spouse_CRM1	S2R_spouse	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_spouse_AVD1	S2R_spouse	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_spouse_ACM1	S2R_spouse	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_spouse_COL2	S2R_spouse	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_spouse_VAL1	S2R_spouse	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_spouse_VAL2	S2R_spouse	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_spouse_VAL3	S2R_spouse	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_spouse_VAL4	S2R_spouse	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_spouse_CONF1	S2R_spouse	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_spouse_FREQ1	S2R_spouse	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_spouse_VIG1	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_coworker_JP1	S2R_coworker	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_coworker_JP2	S2R_coworker	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_manager_EI1	S2R_manager	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_manager_EI2	S2R_manager	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_coworker_COM1	S2R_coworker	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_coworker_COL1	S2R_coworker	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_coworker_CRM1	S2R_coworker	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_coworker_AVD1	S2R_coworker	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_coworker_ACM1	S2R_coworker	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_coworker_VAL1	S2R_coworker	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_coworker_VAL2	S2R_coworker	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_coworker_VAL3	S2R_coworker	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_coworker_VAL4	S2R_coworker	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_coworker_PRO1	S2R_coworker	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_coworker_PRO2	S2R_coworker	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_coworker_PRO3	S2R_coworker	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_coworker_PRO4	S2R_coworker	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_coworker_CONF1	S2R_coworker	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_coworker_FREQ1	S2R_coworker	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_coworker_VIG1	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_manager_SN1	S2R_manager	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_manager_SN2	S2R_manager	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_manager_TF1	S2R_manager	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_manager_TF2	S2R_manager	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_manager_COM1	S2R_manager	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_manager_COL1	S2R_manager	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_manager_CRM1	S2R_manager	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_manager_AVD1	S2R_manager	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_manager_ACM1	S2R_manager	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_manager_VAL1	S2R_manager	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_manager_VAL2	S2R_manager	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_manager_VAL3	S2R_manager	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_manager_VAL4	S2R_manager	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_manager_PRO1	S2R_manager	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_manager_PRO2	S2R_manager	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_manager_PRO3	S2R_manager	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_manager_PRO4	S2R_manager	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_manager_CONF1	S2R_manager	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_manager_FREQ1	S2R_manager	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_manager_VIG1	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_direct_report_EI1	S2R_direct_report	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_direct_report_COM1	S2R_direct_report	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_direct_report_COL1	S2R_direct_report	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_direct_report_CRM1	S2R_direct_report	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_direct_report_AVD1	S2R_direct_report	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_direct_report_ACM1	S2R_direct_report	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_direct_report_COL2	S2R_direct_report	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_direct_report_VAL1	S2R_direct_report	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_direct_report_VAL2	S2R_direct_report	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_direct_report_VAL3	S2R_direct_report	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_direct_report_VAL4	S2R_direct_report	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S0_CHRONOTYPE	S0_profile	Relationship	Chronotype	Kronotip (Gün içinde en verimli olduğunuz zaman dilimi):	SingleChoice	Sabah|Akşam|Karışık	0	\N	1	\N	13	RELATIONSHIP
S2R_direct_report_PRO1	S2R_direct_report	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_direct_report_PRO2	S2R_direct_report	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_direct_report_PRO3	S2R_direct_report	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_direct_report_VIG1	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_direct_report_VIG2	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_direct_report_VIG3	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_direct_report_VIG4	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_client_EI1	S2R_client	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_client_EI2	S2R_client	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_client_SN1	S2R_client	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_client_SN2	S2R_client	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_client_TF1	S2R_client	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_client_TF2	S2R_client	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_client_COM1	S2R_client	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_client_COL1	S2R_client	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_client_CRM1	S2R_client	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_client_AVD1	S2R_client	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_client_ACM1	S2R_client	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_client_COL2	S2R_client	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_client_VAL1	S2R_client	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_client_VAL2	S2R_client	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_client_VAL3	S2R_client	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_client_VAL4	S2R_client	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_client_PRO1	S2R_client	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_client_PRO2	S2R_client	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_client_PRO3	S2R_client	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_direct_report_CONF1	S2R_direct_report	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_direct_report_FREQ1	S2R_direct_report	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_client_VIG1	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_client_VIG2	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_vendor_EI1	S2R_vendor	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_vendor_EI2	S2R_vendor	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_vendor_SN1	S2R_vendor	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_vendor_SN2	S2R_vendor	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_vendor_TF1	S2R_vendor	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_vendor_COM1	S2R_vendor	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_vendor_COL1	S2R_vendor	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_vendor_CRM1	S2R_vendor	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_vendor_AVD1	S2R_vendor	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_vendor_ACM1	S2R_vendor	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_vendor_COL2	S2R_vendor	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_vendor_VAL1	S2R_vendor	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_vendor_VAL2	S2R_vendor	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_vendor_VAL3	S2R_vendor	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_vendor_VAL4	S2R_vendor	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S0_TIME_BUDGET_HRS	S0_profile	Relationship	TimeBudget	İlişkilere ayırabildiğiniz zaman (haftalık saat):	Number		0	\N	1	\N	14	RELATIONSHIP
S2R_vendor_PRO1	S2R_vendor	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_vendor_PRO2	S2R_vendor	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_vendor_PRO3	S2R_vendor	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_vendor_PRO4	S2R_vendor	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_client_CONF1	S2R_client	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_client_FREQ1	S2R_client	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_client_VIG3	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_client_VIG4	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_mentor_EI1	S2R_mentor	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mentor_EI2	S2R_mentor	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mentor_SN1	S2R_mentor	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mentor_SN2	S2R_mentor	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mentor_TF1	S2R_mentor	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mentor_TF2	S2R_mentor	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mentor_COM1	S2R_mentor	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentor_COL1	S2R_mentor	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentor_CRM1	S2R_mentor	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentor_AVD1	S2R_mentor	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentor_ACM1	S2R_mentor	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentor_COL2	S2R_mentor	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentor_PRO1	S2R_mentor	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_mentor_PRO2	S2R_mentor	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_mentor_PRO3	S2R_mentor	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_mentor_PRO4	S2R_mentor	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_vendor_CONF1	S2R_vendor	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_vendor_FREQ1	S2R_vendor	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_vendor_VIG1	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_vendor_VIG2	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_vendor_VIG3	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_mentee_EI1	S2R_mentee	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mentee_EI2	S2R_mentee	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mentee_SN1	S2R_mentee	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mentee_SN2	S2R_mentee	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mentee_TF1	S2R_mentee	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mentee_TF2	S2R_mentee	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mentee_COM1	S2R_mentee	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentee_COL1	S2R_mentee	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentee_CRM1	S2R_mentee	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentee_AVD1	S2R_mentee	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentee_ACM1	S2R_mentee	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentee_COL2	S2R_mentee	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_mentor_VAL1	S2R_mentor	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mentor_VAL2	S2R_mentor	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mentor_VAL3	S2R_mentor	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mentor_VAL4	S2R_mentor	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mentor_CONF1	S2R_mentor	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_mentor_FREQ1	S2R_mentor	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_mentor_VIG1	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_mentor_VIG2	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S3_EI_2	S3_self	MBTI	EI	Yeni bir ortama girdiğimde: A) hızlıca kaynaşırım B) önce gözlemler sonra dahil olurum	ForcedChoice2	A|B	0	{"A": "E", "B": "I"}	1	\N	\N	MBTI
S2R_mentee_VAL1	S2R_mentee	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mentee_VAL2	S2R_mentee	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mentee_VAL3	S2R_mentee	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mentee_VAL4	S2R_mentee	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_1	S4_family	ValuesBoundaries	BOUND	Aile içinde kişisel mahremiyete saygı önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_2	S4_family	ValuesBoundaries	COMM	Zor konuları sakin bir dille konuşabilmeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_3	S4_family	ValuesBoundaries	ROLE	Ev içi roller net olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_4	S4_family	ValuesBoundaries	SUPPORT	Duygusal destek göstermek değerlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_5	S4_family	ValuesBoundaries	BOUND	Özel eşyaları izinsiz kullanmak kabul edilemez.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S2R_mentee_PRO2	S2R_mentee	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_mentee_PRO3	S2R_mentee	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_mentee_PRO4	S2R_mentee	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_mentee_CONF1	S2R_mentee	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	QUALITY_CHECK
S2R_mentee_FREQ1	S2R_mentee	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N	QUALITY_CHECK
S2R_mentee_VIG1	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_mentee_VIG2	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S4_romantic_16	S4_romantic	ValuesBoundaries	SUPPORT	Zor günlerde yanında olmasını beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_17	S4_romantic	ValuesBoundaries	FUN	Birlikte keyifli rutini sürdürmek isterim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_19	S4_romantic	ValuesBoundaries	TRUST	Şeffaflık ve dürüstlük esastır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S0_SUPPORT_SIZE	S0_profile	Support	Circle	Yakın destek halkası (kişi sayısı):	Number		0	\N	1	\N	27	RELATIONSHIP
S0_LOVE_LANG_ORDER	S0_profile	Romantic	LoveLangs	Sevgi dillerim (öncelik sırası—seçim sırasına göre):	RankedMulti	Onay sözleri|Kaliteli zaman|Hizmet|Hediye|Temas	0	\N	1	Sadece romantik bağlamda gösterin.	29	RELATIONSHIP
S0_TOUCH_COMFORT	S0_profile	Romantic	TouchComfort	Fiziksel temas rahatlığım:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	Sadece romantik bağlamda gösterin.	30	RELATIONSHIP
S0_COPING	S0_profile	Support	Coping	Sık kullandığım başa çıkma stratejileri:	OpenText		0	\N	1	Örn: Yürüyüş, meditasyon, müzik dinleme, arkadaşlarla konuşma...	28	RELATIONSHIP
S0_REL_STATUS	S0_profile	Relationship	Status	Medeni/İlişki durumunuz:	SingleChoice	Bekâr|İlişkim var|Nişanlı|Evli|Ayrı yaşıyorum|Boşanmış|Diğer	0	\N	1	\N	10	RELATIONSHIP
S0_LIVE_WITH	S0_profile	Relationship	Household	Birlikte yaşadıklarım:	MultiSelect	Yalnız|Ailemle|Ev arkadaşı|Partner|Çocuk(lar)|Bakımını üstlendiğim biri	0	\N	1	\N	11	RELATIONSHIP
S0_CARE_DUTIES	S0_profile	Relationship	Care	Bakım sorumluluğu:	MultiSelect	Çocuk|Yaşlı yakını|Engelli yakını|Evcil hayvan|Yok	0	\N	1	\N	12	RELATIONSHIP
S0_AGE	S0_profile	Demographics	Age	Yaşınız (sayı olarak):	Number		0	\N	1	\N	1	DEMOGRAPHICS
S0_GENDER	S0_profile	Demographics	Gender	Cinsiyetiniz (opsiyonel):	SingleChoice	Kadın|Erkek|Diğer|Belirtmek istemiyorum	0	\N	1	\N	2	DEMOGRAPHICS
S0_WORK_STATUS	S0_profile	EducationWork	WorkStatus	Şu an çalışma durumunuz:	SingleChoice	Çalışıyorum|Çalışmıyorum|İş arıyorum|Serbest	0	\N	1	\N	3	DEMOGRAPHICS
S0_STUDY_ACTIVE	S0_profile	EducationWork	StudyActive	Öğrenim durumunuz:	SingleChoice	Okuyorum|Okumuyorum	0	\N	1	\N	4	DEMOGRAPHICS
S0_SCHOOL_TYPE	S0_profile	EducationWork	SchoolType	Son/Güncel okul türü:	SingleChoice	Lise|Ön lisans|Lisans (Üniversite)|Yüksek Lisans|Doktora|Diğer	0	\N	1	Etiket: Okuyorum→Güncel okul; Okumuyorum→Son mezun olunan okul	5	DEMOGRAPHICS
S0_WORK_PACE	S0_profile	EducationWork	Pace	Çalışma/okul temposu:	SingleChoice	Düzenli mesai|Vardiya|Serbest|Yoğun dönemli	0	\N	1	\N	7	DEMOGRAPHICS
S0_STRESS_NOW	S0_profile	EducationWork	Stress	Güncel stres düzeyim:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	\N	8	DEMOGRAPHICS
S0_COMMUTE_MIN	S0_profile	EducationWork	Commute	Günlük yol/lojistik yük (dakika):	Number		0	\N	1	Opsiyonel	9	DEMOGRAPHICS
S0_REL_GOALS	S0_profile	Goals	RelGoals	İlişkilerde kısa/orta vadeli hedefleriniz:	OpenText		0	\N	1	Örn: Daha iyi iletişim kurmak, güven inşa etmek, sınırları belirlemek...	19	GOALS
S0_BOUNDARIES	S0_profile	Goals	Boundaries	Sınırlarınız / kırmızı çizgileriniz:	OpenText		0	\N	1	Örn: Yalan, aldatma, saygısızlık, şiddet...	20	GOALS
S0_LIFE_GOAL	S0_profile	Goals	LifePurpose	Hayattaki amacınız / yönünüz:	OpenText		0	\N	1	Örn: İnsanlara yardım etmek, sürekli öğrenmek, aileme iyi bir hayat sağlamak...	18	GOALS
S0_TOP_CHALLENGES	S0_profile	Challenges	TopChallenges	Sizi şu an en çok zorlayan konular:	OpenText		0	\N	1	Örn: İş yükü, aile ilişkileri, maddi konular, sağlık...	21	CHALLENGES
S0_NEAR_TERM	S0_profile	Challenges	NearTerm	Yakın zamanda çözmeniz gereken güçlük(ler):	OpenText		0	\N	1	Örn: Yeni iş bulma, taşınma, borç ödeme, sınav hazırlık...	22	CHALLENGES
S0_TRIGGERS	S0_profile	Challenges	Triggers	Bilinen çatışma tetikleyicilerim:	OpenText		0	\N	1	Örn: Alaycı üslup, eleştiri, plansızlık, ses tonu...	23	CHALLENGES
S0_LIKES	S0_profile	Preferences	Likes	Sevdiğiniz şeyler (aktiviteler insanlar ortamlar):	OpenText		0	\N	1	Örn: Açık havada vakit geçirmek, derin sohbetler, yeni yerler keşfetmek...	16	PREFERENCES
S0_DISLIKES	S0_profile	Preferences	Dislikes	Sevmediğiniz / kaçındığınız şeyler:	OpenText		0	\N	1	Örn: Gürültülü ortamlar, geç kalınması, yalan söylenmesi...	17	PREFERENCES
S0_HOBBIES	S0_profile	Preferences	Hobbies	Hobileriniz / ilgi alanlarınız:	OpenText		0	\N	1	Örn: Kitap okuma, yüzme, müzik, doğa yürüyüşü, yemek yapma...	15	PREFERENCES
S0_CONSENT	S0_profile	Consent	Use	Analiz ve koçluk için verdiğim bilgilerin işlenmesini onaylıyorum.	SingleChoice	Evet|Hayır	0	\N	1	\N	31	CONSENT
S0_WHY_NEED	S0_profile	Consent	WhyNeed	Bu uygulamaya neden ihtiyaç duydunuz? (Anket amaçlı değil sizi tanımak ve ihtiyaçlarınızı anlamak için)	OpenText		0	\N	1	Örn: İlişkilerimi geliştirmek, kendimi tanımak, çatışmaları çözmek istiyorum...	32	CONSENT
S1_BF_E1	S1_self	BigFive	E	Sosyal ortamlarda enerji toplarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_E2	S1_self	BigFive	E	Yeni insanlarla tanışmak beni heyecanlandırır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_E3	S1_self	BigFive	E	Kalabalık etkinlikler beni yorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S1_BF_E4	S1_self	BigFive	E	Topluluk önünde konuşmaktan keyif alırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_A1	S1_self	BigFive	A	İnsanların bakış açısını anlamaya çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_A2	S1_self	BigFive	A	Anlaşmazlıklarda empati kurarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_A3	S1_self	BigFive	A	Eleştirirken sözlerimi özenle seçerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_A4	S1_self	BigFive	A	Kendi ihtiyaçlarımı her zaman öne koyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S1_BF_C1	S1_self	BigFive	C	Planları önceden yapar ve takip ederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_C2	S1_self	BigFive	C	Detayları gözden kaçırmam.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_C3	S1_self	BigFive	C	Son dakika işleri severim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S1_BF_C4	S1_self	BigFive	C	Söz verdiğim işi vaktinde bitiririm.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_N1	S1_self	BigFive	N	Stresliyken kolayca gerginleşirim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_N2	S1_self	BigFive	N	Eleştirilere karşı hassasım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_N3	S1_self	BigFive	N	Zor durumda soğukkanlı kalırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S1_BF_N4	S1_self	BigFive	N	Gelecek hakkında sık endişe duyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_O1	S1_self	BigFive	O	Yeni fikir ve deneyimlere açığım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_O2	S1_self	BigFive	O	Rutini kırmayı severim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S1_BF_O3	S1_self	BigFive	O	Alışılmış yöntemler dışına çıkmam.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S1_BF_O4	S1_self	BigFive	O	Sanat/yaratıcılık içeren şeylerden keyif alırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mother_E1	S2R_mother	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mother_A1	S2R_mother	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mother_C1	S2R_mother	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mother_N1	S2R_mother	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mother_O1	S2R_mother	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mother_E2	S2R_mother	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_father_E1	S2R_father	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_father_A1	S2R_father	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_father_C1	S2R_father	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_father_N1	S2R_father	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_father_O1	S2R_father	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_father_E2	S2R_father	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_sibling_E1	S2R_sibling	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_sibling_A1	S2R_sibling	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_sibling_C1	S2R_sibling	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_sibling_N1	S2R_sibling	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_sibling_O1	S2R_sibling	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_sibling_E2	S2R_sibling	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_relative_E1	S2R_relative	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_relative_A1	S2R_relative	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_relative_C1	S2R_relative	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_relative_N1	S2R_relative	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_relative_O1	S2R_relative	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_relative_E2	S2R_relative	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_best_friend_E1	S2R_best_friend	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_best_friend_A1	S2R_best_friend	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_best_friend_C1	S2R_best_friend	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_best_friend_N1	S2R_best_friend	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_best_friend_O1	S2R_best_friend	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_best_friend_E2	S2R_best_friend	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_friend_E1	S2R_friend	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_friend_A1	S2R_friend	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_friend_C1	S2R_friend	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_friend_N1	S2R_friend	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_friend_O1	S2R_friend	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_friend_E2	S2R_friend	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_roommate_E1	S2R_roommate	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_roommate_A1	S2R_roommate	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_roommate_C1	S2R_roommate	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_roommate_N1	S2R_roommate	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_roommate_O1	S2R_roommate	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_roommate_E2	S2R_roommate	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_neighbor_E1	S2R_neighbor	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_neighbor_A1	S2R_neighbor	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_neighbor_C1	S2R_neighbor	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_neighbor_N1	S2R_neighbor	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_neighbor_O1	S2R_neighbor	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_neighbor_E2	S2R_neighbor	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_crush_E1	S2R_crush	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_crush_A1	S2R_crush	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_crush_C1	S2R_crush	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_crush_N1	S2R_crush	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_crush_O1	S2R_crush	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_crush_E2	S2R_crush	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_date_E1	S2R_date	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_date_A1	S2R_date	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_date_C1	S2R_date	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_date_N1	S2R_date	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_date_O1	S2R_date	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_date_E2	S2R_date	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_partner_E1	S2R_partner	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_partner_A1	S2R_partner	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_partner_C1	S2R_partner	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_partner_N1	S2R_partner	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_partner_O1	S2R_partner	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_partner_E2	S2R_partner	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_fiance_E1	S2R_fiance	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_fiance_A1	S2R_fiance	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_fiance_C1	S2R_fiance	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_fiance_N1	S2R_fiance	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_fiance_O1	S2R_fiance	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_fiance_E2	S2R_fiance	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_spouse_E1	S2R_spouse	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_spouse_A1	S2R_spouse	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_spouse_C1	S2R_spouse	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_spouse_N1	S2R_spouse	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_spouse_O1	S2R_spouse	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_spouse_E2	S2R_spouse	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_coworker_E1	S2R_coworker	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_coworker_A1	S2R_coworker	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_coworker_C1	S2R_coworker	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_coworker_N1	S2R_coworker	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_coworker_O1	S2R_coworker	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_coworker_E2	S2R_coworker	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_manager_E1	S2R_manager	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_manager_A1	S2R_manager	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_manager_C1	S2R_manager	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_manager_N1	S2R_manager	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_manager_O1	S2R_manager	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_manager_E2	S2R_manager	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_direct_report_E1	S2R_direct_report	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_direct_report_A1	S2R_direct_report	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_direct_report_C1	S2R_direct_report	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_direct_report_N1	S2R_direct_report	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_direct_report_O1	S2R_direct_report	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_direct_report_E2	S2R_direct_report	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_client_E1	S2R_client	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_client_A1	S2R_client	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_client_C1	S2R_client	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_client_N1	S2R_client	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_client_O1	S2R_client	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_client_E2	S2R_client	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_vendor_E1	S2R_vendor	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_vendor_A1	S2R_vendor	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_vendor_C1	S2R_vendor	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_vendor_N1	S2R_vendor	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_vendor_O1	S2R_vendor	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_vendor_E2	S2R_vendor	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_mentor_E1	S2R_mentor	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mentor_A1	S2R_mentor	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mentor_C1	S2R_mentor	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mentor_N1	S2R_mentor	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mentor_O1	S2R_mentor	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mentor_E2	S2R_mentor	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S2R_mentee_E1	S2R_mentee	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mentee_A1	S2R_mentee	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mentee_C1	S2R_mentee	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mentee_N1	S2R_mentee	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mentee_O1	S2R_mentee	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	BIG_FIVE
S2R_mentee_E2	S2R_mentee	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	BIG_FIVE
S1_DISC_SJT1	S1_self	DISC	DISC	Evde acil karar gerektiren bir durum var (örn. su sızıntısı); ilk tutumunuz?	MultiChoice4	Ana vanayı kapatır, ustayı arar, gerekirse komşuyu bilgilendiririm.|Mahalle/WhatsApp grubunda yardım çağırır, çevreyi hızla organize ederim.|Evdeki herkesin sakin olduğundan emin olur, görevleri paylaşarak destek olurum.|Kaynağı kontrol eder, foto/video ile durumu belgeleyip sigorta/yönetimle prosedürü başlatırım.	0	\N	1	\N	70	DISC
S1_DISC_SJT3	S1_self	DISC	DISC	Aldığınız üründe sorun çıktı; ilk odağınız?	MultiChoice4	Satıcıyla hemen iletişime geçip değişim/iade talep ederim.|Müşteri temsilcisiyle olumlu bir diyalog kurup çözümü hızlandırırım.|Yakın çevreme danışıp birlikte en pratik adımı atarım.|Fatura/garanti ve arıza notlarını toplayıp üretici kılavuzuna göre ilerlerim.	0	\N	1	\N	72	DISC
S1_DISC_SJT4	S1_self	DISC	DISC	Plan dışı değişiklik talebi geldi (örn. tatil rotası); refleksiniz?	MultiChoice4	Yeni rotayı hızla belirleyip programa geçiririm.|Değişikliğin cazibesini anlatarak grubu ikna ederim.|Herkesin rahat edeceği orta yolu bulmak için öneri toplarım.|Alternatifleri süre/maliyet/riske göre kısa karşılaştırır, veriye dayalı öneri getiririm.	0	\N	1	\N	73	DISC
S1_DISC_SJT6	S1_self	DISC	DISC	Yakın çevrede moral düşük (ör. arkadaş üzgün); ilk hamleniz?	MultiChoice4	Pratik çözüm seçenekleri çıkarır, küçük bir aksiyon planı yaparım.|Moral yükselten bir sohbet/aktivite organize ederim.|Yanında sakince bulunur, dinler ve duygusal destek veririm.|Durumu sistematik değerlendirir, uygun kaynak/uzman öneririm.	0	\N	1	\N	75	DISC
S1_DISC_SJT7	S1_self	DISC	DISC	Aynı zamana denk gelen aile ve arkadaş planları çakıştı; yaklaşımınız?	MultiChoice4	Önceliklendirme yapar, net bir karar verip birini iptal ederim.|Herkese yazıp esnek, yeni ortak bir zaman bulmaya çalışırım.|Kimseyi kırmamak için kısa süreli/ardışık katılım planlarım.|Takvim/lojistik analiz yapar, en verimli seçeneği seçerim.	0	\N	1	\N	76	DISC
S1_DISC_SJT9	S1_self	DISC	DISC	Komşudan gece geç saatte yüksek ses geliyor; ilk yaklaşımınız ne olur?	MultiChoice4	Kapısını çalar, netçe rahatsızlığı iletip sesin kısılmasını isterim.|Site/WhatsApp grubunda kibar bir mesajla konuyu anlatır, destek isterim.|Sabah uygun bir zamanda sakin bir dille konuşmayı teklif ederim.|Site kuralları/yönetmeliği kontrol edip uygun kanaldan resmi bildirim yaparım.	0	\N	1	\N	78	DISC
S1_DISC_SJT10	S1_self	DISC	DISC	Ortak kullanılan ev/mutfakta bulaşıklar birikiyor; nasıl ilerlersiniz?	MultiChoice5	Bundan sonra kuralları ben koyarım; herkes uysun.|Birlikte küçük bir plan yapalım (takvim, görev paylaşımı).|Herkes biraz taviz versin; bugün ben hallederim, yarın siz.|Şimdilik görmezden gelelim; uygun zamanda konuşuruz.|Ben hallederim; siz nasıl rahatsanız öyle olsun.	0	\N	1	\N	79	DISC
S2R_mother_TF1	S2R_mother	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mother_TF2	S2R_mother	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mother_JP1	S2R_mother	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mother_JP2	S2R_mother	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_father_JP1	S2R_father	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_father_JP2	S2R_father	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_sibling_TF2	S2R_sibling	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_sibling_JP1	S2R_sibling	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_sibling_JP2	S2R_sibling	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_relative_JP1	S2R_relative	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_relative_JP2	S2R_relative	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_best_friend_JP1	S2R_best_friend	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_best_friend_JP2	S2R_best_friend	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_roommate_TF2	S2R_roommate	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_roommate_JP1	S2R_roommate	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_roommate_JP2	S2R_roommate	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_neighbor_SN2	S2R_neighbor	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_neighbor_TF1	S2R_neighbor	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_neighbor_TF2	S2R_neighbor	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_neighbor_JP1	S2R_neighbor	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_neighbor_JP2	S2R_neighbor	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_crush_JP1	S2R_crush	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_crush_JP2	S2R_crush	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_date_TF2	S2R_date	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_date_JP1	S2R_date	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_date_JP2	S2R_date	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_partner_TF2	S2R_partner	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_partner_JP1	S2R_partner	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_partner_JP2	S2R_partner	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_fiance_JP1	S2R_fiance	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_fiance_JP2	S2R_fiance	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_spouse_JP1	S2R_spouse	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_spouse_JP2	S2R_spouse	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_coworker_TF2	S2R_coworker	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_manager_JP1	S2R_manager	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_manager_JP2	S2R_manager	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_direct_report_EI2	S2R_direct_report	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_direct_report_SN1	S2R_direct_report	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_direct_report_SN2	S2R_direct_report	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_direct_report_TF1	S2R_direct_report	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_direct_report_TF2	S2R_direct_report	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_direct_report_JP1	S2R_direct_report	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_direct_report_JP2	S2R_direct_report	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_client_JP1	S2R_client	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_client_JP2	S2R_client	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_vendor_TF2	S2R_vendor	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_vendor_JP1	S2R_vendor	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_vendor_JP2	S2R_vendor	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mentor_JP1	S2R_mentor	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mentor_JP2	S2R_mentor	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S2R_mentee_JP1	S2R_mentee	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	MBTI
S2R_mentee_JP2	S2R_mentee	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N	MBTI
S3_EI_1	S3_self	MBTI	EI	Yoğun bir günün sonunda enerjimi yenilemek için: A) insanlarla vakit geçiririm B) yalnız kalırım	ForcedChoice2	A|B	0	{"A": "E", "B": "I"}	1	\N	\N	MBTI
S3_EI_3	S3_self	MBTI	EI	Beyin fırtınasında: A) yüksek sesle düşünürüm B) önce zihnimde netleştiririm	ForcedChoice2	A|B	0	{"A": "E", "B": "I"}	1	\N	\N	MBTI
S3_SN_1	S3_self	MBTI	SN	Bir projeyi tartışırken önce: A) somut detay/kanıt B) büyük resim/olasılık	ForcedChoice2	A|B	0	{"A": "S", "B": "N"}	1	\N	\N	MBTI
S3_SN_2	S3_self	MBTI	SN	Bir konuyu anlamak için: A) mevcut gerçekler B) olası senaryolar	ForcedChoice2	A|B	0	{"A": "S", "B": "N"}	1	\N	\N	MBTI
S3_SN_3	S3_self	MBTI	SN	Yenilik karşısında: A) işe yararlık B) potansiyel fırsat	ForcedChoice2	A|B	0	{"A": "S", "B": "N"}	1	\N	\N	MBTI
S3_TF_1	S3_self	MBTI	TF	Zor bir kararda: A) tutarlılık/adalet B) duygusal etki	ForcedChoice2	A|B	0	{"A": "T", "B": "F"}	1	\N	\N	MBTI
S3_TF_2	S3_self	MBTI	TF	Geri bildirim verirken: A) net/doğrudan B) hissi gözeterek	ForcedChoice2	A|B	0	{"A": "T", "B": "F"}	1	\N	\N	MBTI
S3_TF_3	S3_self	MBTI	TF	Çatışmada: A) problemi mantıkla çözerim B) duygusal etkiyi önce ele alırım	ForcedChoice2	A|B	0	{"A": "T", "B": "F"}	1	\N	\N	MBTI
S3_JP_1	S3_self	MBTI	JP	Planlar: A) net takvim/kapalı uçlu B) seçenekler açık/akışkan	ForcedChoice2	A|B	0	{"A": "J", "B": "P"}	1	\N	\N	MBTI
S3_JP_2	S3_self	MBTI	JP	Son dakika değişimi: A) rahatsız eder B) esnek davranırım	ForcedChoice2	A|B	0	{"A": "J", "B": "P"}	1	\N	\N	MBTI
S3_JP_3	S3_self	MBTI	JP	Görev stili: A) bitişten önce tamamlarım B) son ana kadar seçenekler açık	ForcedChoice2	A|B	0	{"A": "J", "B": "P"}	1	\N	\N	MBTI
S1_AT_AVO2	S1_self	Attachment	AVO	Yakınlık arttığında bir miktar geri çekilme ihtiyacı duyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S1_AT_AVO3	S1_self	Attachment	AVO	Bağımsızlık alanım kısıtlanınca huzursuz olurum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S1_AT_AVO4	S1_self	Attachment	AVO	Partnerimin duygusal ihtiyaçlarını karşılamak yorucu gelebilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S1_AT_AVO5	S1_self	Attachment	AVO	Problem olduğunda konuyu ertelemeyi tercih ederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S1_AT_AVO6	S1_self	Attachment	AVO	Kişisel alanımın korunması benim için çok önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	ATTACHMENT
S4_family_20	S4_family	ValuesBoundaries	REPAIR	Kırgınlıkta özür ve onarım beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S1_TKI_5	S1_self	Conflict	ACCOM	Yakınınız bir konuda duygusal olarak çok yoğun; yaklaşımınız?	MultiChoice5	Konuyu çözüme bağlamak için yönlendirir, somut adımlar belirlerim.|Hisleri ve ihtiyaçları birlikte konuşur, ortak plan çıkarırız.|Biraz konuşup orta noktada buluşalım, sonra kapatalım derim.|Şu an uygun değil; sakinleşince konuşalım derim.|Ne istiyorsa öyle yaparım; ona uyarım.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	\N	\N	CONFLICT_STYLE
S1_TKI_7	S1_self	Conflict	COMPETE	Bir konuda doğru olduğunuzdan eminsiniz ve kanıt elinizde; stratejiniz?	MultiChoice5	Kanıtları sunar, kararı netleştiririm.|Kanıtları paylaşıp birlikte değerlendirir, ortak karar alırız.|Zaman kaybetmemek için kısmi uzlaşma öneririm.|Tartışmayı uzatmam; konuyu büyütmeden geçerim.|Karşı tarafı kırmamak için kendi görüşümden vazgeçerim.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	\N	\N	CONFLICT_STYLE
S2R_friend_COL2	S2R_friend	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_roommate_COL2	S2R_roommate	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_crush_AVD1	S2R_crush	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_crush_ACM1	S2R_crush	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_crush_COL2	S2R_crush	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_date_AVD1	S2R_date	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_date_ACM1	S2R_date	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_date_COL2	S2R_date	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_partner_AVD1	S2R_partner	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_partner_ACM1	S2R_partner	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_partner_COL2	S2R_partner	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_coworker_COL2	S2R_coworker	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S2R_manager_COL2	S2R_manager	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	CONFLICT_STYLE
S4_family_6	S4_family	ValuesBoundaries	COMM	Eleştiride kırıcı olmamaya özen gösterilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_7	S4_family	ValuesBoundaries	DECISION	Önemli kararlar ortak alınmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_8	S4_family	ValuesBoundaries	TIME	Aile zamanı için düzenli vakit ayırmak önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_9	S4_family	ValuesBoundaries	CONFLICT	Gerilimde kısa mola verip yeniden konuşabilmeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_10	S4_family	ValuesBoundaries	RESPECT	Kuşak farkı olsa da saygı korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_11	S4_family	ValuesBoundaries	FINANCE	Hane içi harcamalarda şeffaflık gerekir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_12	S4_family	ValuesBoundaries	BOUND	Misafir/ziyaret planında önceden haber verilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_13	S4_family	ValuesBoundaries	SUPPORT	Krizde ulaşılabilir olmak önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_14	S4_family	ValuesBoundaries	INDEP	Bağımsızlık alanına saygı duyulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_15	S4_family	ValuesBoundaries	DIGI	Dijital/telefon gizliliği gözetilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_16	S4_family	ValuesBoundaries	PRIV	Aile sırları üçüncü kişilerle paylaşılmamalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_17	S4_family	ValuesBoundaries	CARE	Hassas konular (sağlık vb.) özenle konuşulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_18	S4_family	ValuesBoundaries	FAIR	Sorumluluklar adil paylaşılmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_family_19	S4_family	ValuesBoundaries	BOUND	Ses yükseltmek sınır ihlalidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_1	S4_friend	ValuesBoundaries	BOUND	Plan değişikliğinde zamanında haber verilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_2	S4_friend	ValuesBoundaries	TRUST	Sırlar gizli tutulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_3	S4_friend	ValuesBoundaries	TIME	Düzenli görüşmeye önem veririm.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_4	S4_friend	ValuesBoundaries	FUN	Ortak aktivite planlamayı severim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_5	S4_friend	ValuesBoundaries	RESPECT	İğneleyici şakalardan kaçınılmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_6	S4_friend	ValuesBoundaries	SUPPORT	Zor günde mesaj/arayış beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_7	S4_friend	ValuesBoundaries	BOUND	Özel hayatımın sınırlarına saygı gösterilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_8	S4_friend	ValuesBoundaries	COMM	Sorunları açık ve sakin konuşabilmeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_9	S4_friend	ValuesBoundaries	FAIR	Harcama paylaşımında adalet önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_10	S4_friend	ValuesBoundaries	DIGI	Ekran görüntülerimi izinsiz paylaşmak kabul edilemez.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_11	S4_friend	ValuesBoundaries	RELIAB	Verilen sözlerin tutulması gerekir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_12	S4_friend	ValuesBoundaries	CONFLICT	Tartışmayı kaçırmadan çözüme odaklanmalıyız.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_13	S4_friend	ValuesBoundaries	FEED	Geri bildirimi iyi niyetle vermeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_14	S4_friend	ValuesBoundaries	PRIOR	Öncelikler çatıştığında açık iletişim beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_15	S4_friend	ValuesBoundaries	BOUND	Rızam olmadan eşyalarım kullanılmamalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_16	S4_friend	ValuesBoundaries	BAL	Karşılıklılık dengesi önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_17	S4_friend	ValuesBoundaries	REPAIR	Kırgınlık sonrası onarım beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_18	S4_friend	ValuesBoundaries	TIME	Son dakika iptalleri minimum olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_19	S4_friend	ValuesBoundaries	TRUST	Gıyabımda saygılı konuşulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_friend_20	S4_friend	ValuesBoundaries	SUPPORT	Başarılarımı takdir etmesini beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_1	S4_work	ValuesBoundaries	PRO	Profesyonel sınırlara özen gösterilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_2	S4_work	ValuesBoundaries	COMM	Geri bildirim açık ve saygılı verilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_3	S4_work	ValuesBoundaries	OWN	Sorumluluk üstlenmek ve takip önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_4	S4_work	ValuesBoundaries	ALIGN	Ekip hedefleriyle hizalanma gereklidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_5	S4_work	ValuesBoundaries	TIME	Toplantı ve teslim tarihlerine uyum esastır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_6	S4_work	ValuesBoundaries	TRUST	Bilgi gizliliği korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_7	S4_work	ValuesBoundaries	BOUND	Mesai dışı yazışmalara makul sınır getirilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_8	S4_work	ValuesBoundaries	FAIR	İş yükü adil dağıtılmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_9	S4_work	ValuesBoundaries	CONFLICT	Uyuşmazlıklar kişiselleştirilmeden ele alınmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_10	S4_work	ValuesBoundaries	RESPECT	Hiyerarşi olsa da saygı korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_11	S4_work	ValuesBoundaries	FEED	Net hedef ve beklenti belirlenmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_12	S4_work	ValuesBoundaries	REPAIR	Hata sonrası onarım/öğrenme beklenir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_13	S4_work	ValuesBoundaries	OWN	Hatalarda sorumluluk almak değerlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_14	S4_work	ValuesBoundaries	BOUND	Kişisel konular iş ortamında sınırında kalmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_15	S4_work	ValuesBoundaries	ALIGN	Kararlar şeffaf iletişilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_16	S4_work	ValuesBoundaries	TRUST	Krediyi hakkaniyetle paylaşmak gerekir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_17	S4_work	ValuesBoundaries	TIME	Fazla mesai beklentisi şeffaf olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_18	S4_work	ValuesBoundaries	PRO	Toplantıda söz kesmemek önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_19	S4_work	ValuesBoundaries	COMM	E-posta/mesaj tonuna dikkat edilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_work_20	S4_work	ValuesBoundaries	SAFETY	Psikolojik güvenlik korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_1	S4_romantic	ValuesBoundaries	BOUND	Özel alan ve kişisel zamana saygı beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_2	S4_romantic	ValuesBoundaries	FINANCE	Maddi konularda şeffaflık isterim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_3	S4_romantic	ValuesBoundaries	COMM	Duyguların düzenli ifade edilmesini isterim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_4	S4_romantic	ValuesBoundaries	DIGI	Sosyal medyada mahremiyete dikkat edilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_5	S4_romantic	ValuesBoundaries	LOYAL	Sadakat kırmızı çizgimdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_6	S4_romantic	ValuesBoundaries	TRUST	Güven inşası için tutarlı davranış beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_7	S4_romantic	ValuesBoundaries	TIME	Kaliteli birlikte zaman önceliklidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_8	S4_romantic	ValuesBoundaries	SEX	Rıza ve sınırlar açık konuşulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_9	S4_romantic	ValuesBoundaries	REPAIR	Kırgınlıkta özür ve telafi beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_10	S4_romantic	ValuesBoundaries	BOUND	Kıskançlık kontrolü ve iletişimle yönetilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_11	S4_romantic	ValuesBoundaries	FAIR	Ev/ilişki sorumlulukları adil bölüşülmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_12	S4_romantic	ValuesBoundaries	FAM	Aile/arkadaş etkisi makul sınırda kalmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_13	S4_romantic	ValuesBoundaries	COMM	Tartışmada ses yükseltmek sınır ihlalidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_14	S4_romantic	ValuesBoundaries	PLAN	Gelecek planlarında fikirlerime değer verilmeli.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_15	S4_romantic	ValuesBoundaries	DIGI	Konum/mesaj denetimi talebi kabul edilemez.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_18	S4_romantic	ValuesBoundaries	BOUND	Flört/iletişim sınırları net olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S4_romantic_20	S4_romantic	ValuesBoundaries	REPAIR	İlişki sorunlarında profesyonel destek opsiyonu açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	VALUES
S0_VALUES_TOP3	S0_profile	Values	Top3	Öncelikli değerlerim (en fazla 3 seçiniz):	MultiSelect	Dürüstlük|Sadakat|Özgürlük|Adalet|Başarı|Şefkat|Düzen|Yaratıcılık|Macera|Güvenlik|Saygı	0	\N	1	Maksimum 3 önerilir.	24	VALUES
S0_MONEY_TALK_EASE	S0_profile	Values	MoneyTalk	Para/sorumluluk konuşma rahatlığım:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	\N	25	VALUES
S0_SOCIAL_VIS_EASE	S0_profile	Values	SocialVisibility	Sosyal medya görünürlüğü rahatlığım:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	\N	26	VALUES
S0_SCHOOL_FIELD	S0_profile	EducationWork	SchoolField	Bölüm/Alan:	OpenText		0	\N	1	Örn: Bilgisayar Mühendisliği, İşletme, Tıp, Hukuk...	6	DEMOGRAPHICS
S2R_direct_report_PRO4	S2R_direct_report	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_client_PRO4	S2R_client	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	PROFESSIONAL
S2R_best_friend_AVAIL4	S2R_best_friend	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_neighbor_AVAIL4	S2R_neighbor	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N	AVAILABILITY
S2R_mother_VIG2	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_mother_VIG3	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_father_VIG4	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_sibling_VIG4	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_relative_VIG2	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_relative_VIG3	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_relative_VIG4	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_best_friend_VIG3	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_best_friend_VIG4	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_friend_VIG3	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_friend_VIG4	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_roommate_VIG4	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_neighbor_VIG4	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_crush_VIG4	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_partner_VIG3	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_partner_VIG4	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_fiance_VIG4	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_spouse_VIG2	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_spouse_VIG3	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_spouse_VIG4	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_coworker_VIG2	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_coworker_VIG3	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_coworker_VIG4	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_manager_VIG2	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_manager_VIG3	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_manager_VIG4	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_vendor_VIG4	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_mentor_VIG3	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_mentor_VIG4	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_mentee_VIG3	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
S2R_mentee_VIG4	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N	VIGNETTE
\.


--
-- Data for Name: language_incidents; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.language_incidents (id, user_id, report_type, user_language, detected_language, content_preview, created_at) FROM stdin;
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.messages (id, session_id, role, content, created_at) FROM stdin;
\.


--
-- Data for Name: monthly_usage_summary; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.monthly_usage_summary (id, user_id, subscription_id, month_year, self_analysis_count, self_reanalysis_count, other_analysis_count, relationship_analysis_count, coaching_tokens_used, total_cost_usd, total_charged_usd, created_at, updated_at) FROM stdin;
ce238c3c-bf7b-4e6b-9d50-6835222621db	5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	\N	2025-08	2	2	0	0	0	1.8312	16.00	2025-08-20 23:00:49.638886	2025-08-20 23:04:20.019725
16dc65f0-dcf6-40ab-a850-abd25f51f8f8	2a1881bf-51c8-4726-ad0e-4206633e351d	\N	2025-08	2	0	0	0	0	0.8246	10.00	2025-08-20 23:10:18.603906	2025-08-20 23:10:18.603906
1320e67f-0399-4b5a-9359-75d0de93d1f9	f55dfb24-6a6e-495d-86c7-897a73ffcb88	\N	2025-08	2	0	0	0	0	0.5666	10.00	2025-08-20 23:11:36.872418	2025-08-20 23:11:36.872418
\.


--
-- Data for Name: payg_pricing; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payg_pricing (id, service_type, price_usd, is_active, created_at, updated_at) FROM stdin;
payg_self	self_analysis	5.00	t	2025-08-19 18:54:08.407814	2025-08-19 18:54:08.407814
payg_self_re	self_reanalysis	3.00	t	2025-08-19 18:54:08.407814	2025-08-19 18:54:08.407814
payg_new_person	new_person	3.00	t	2025-08-19 18:54:08.407814	2025-08-19 18:54:08.407814
payg_person_re	same_person_reanalysis	2.00	t	2025-08-19 18:54:08.407814	2025-08-19 18:54:08.407814
payg_relationship	relationship	3.00	t	2025-08-19 18:54:08.407814	2025-08-19 18:54:08.407814
payg_relationship_re	relationship_reanalysis	2.00	t	2025-08-19 18:54:08.407814	2025-08-19 18:54:08.407814
payg_coaching_100k	coaching_100k	5.00	t	2025-08-19 18:54:08.407814	2025-08-19 18:54:08.407814
payg_coaching_500k	coaching_500k	20.00	t	2025-08-19 18:54:08.407814	2025-08-19 18:54:08.407814
\.


--
-- Data for Name: payg_purchases; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payg_purchases (id, user_id, service_type, quantity, unit_price, total_price, payment_status, payment_method, transaction_id, created_at, updated_at, iap_transaction_id) FROM stdin;
\.


--
-- Data for Name: people; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.people (id, user_id, label, relation_type, gender, age, notes) FROM stdin;
\.


--
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reports (id, owner_user_id, dyad_id, markdown, version) FROM stdin;
\.


--
-- Data for Name: responses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.responses (id, assessment_id, item_id, value, rt_ms) FROM stdin;
\.


--
-- Data for Name: scores; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.scores (id, assessment_id, bigfive_json, mbti_json, enneagram_json, attachment_json, conflict_json, social_json, quality_flags) FROM stdin;
\.


--
-- Data for Name: subscription_plans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.subscription_plans (id, name, self_analysis_limit, self_reanalysis_limit, other_analysis_limit, relationship_analysis_limit, coaching_tokens_limit, price_usd, is_active, created_at, updated_at) FROM stdin;
standard	Standart	1	2	8	8	200000000	20.00	t	2025-08-19 18:54:08.406793	2025-08-19 21:17:54.806216
extra	Extra	1	5	25	25	500000000	50.00	t	2025-08-19 18:54:08.406793	2025-08-19 21:17:54.831953
\.


--
-- Data for Name: token_costs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.token_costs (id, model_name, input_cost_per_1k, output_cost_per_1k, is_active, created_at, updated_at) FROM stdin;
gpt-4	gpt-4	0.030000	0.060000	t	2025-08-19 18:54:08.408226	2025-08-19 18:54:08.408226
gpt-4-turbo	gpt-4-turbo-preview	0.010000	0.030000	t	2025-08-19 18:54:08.408226	2025-08-19 18:54:08.408226
gpt-3.5-turbo	gpt-3.5-turbo	0.000500	0.001500	t	2025-08-19 18:54:08.408226	2025-08-19 18:54:08.408226
gpt-4o	gpt-4o	0.005000	0.015000	t	2025-08-19 18:54:08.408226	2025-08-19 18:54:08.408226
gpt-4o-mini	gpt-4o-mini	0.000150	0.000600	t	2025-08-19 18:54:08.408226	2025-08-19 18:54:08.408226
\.


--
-- Data for Name: usage_tracking; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usage_tracking (id, user_id, service_type, target_id, is_reanalysis, tokens_used, input_tokens, output_tokens, cost_usd, price_charged_usd, subscription_id, created_at) FROM stdin;
c3563adb-da6d-446c-8c32-8b328780099d	5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	self_analysis	self	f	13371	4761	5331	0.4627	5.00	\N	2025-08-20 23:00:49.638886
89384bd5-2192-4d4f-ab4d-039d0e1a55bf	5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	self_analysis	self	t	12614	4757	5169	0.4529	3.00	\N	2025-08-20 23:04:20.019725
777783c4-ab17-4d14-953a-a03e1b1475d4	2a1881bf-51c8-4726-ad0e-4206633e351d	self_analysis	self	f	15756	4796	4474	0.4123	5.00	\N	2025-08-20 23:10:18.603906
a5938d11-5b21-44ba-80dc-714fe5eddb52	f55dfb24-6a6e-495d-86c7-897a73ffcb88	self_analysis	self	f	8643	3976	2733	0.2833	5.00	\N	2025-08-20 23:11:36.872418
\.


--
-- Data for Name: user_lifecoaching_notes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_lifecoaching_notes (user_id, notes, created_at, updated_at) FROM stdin;
ebe6eee2-01ae-4753-9737-0983b0330880	{"do_not": [], "language": "tr", "routines": [], "timezone": null, "triggers": [], "boundaries": [], "coach_tone": "short, formal", "values_top3": [], "communication": {"contact_freq": "", "feedback_style": "", "preferred_channels": [], "privacy_expectation_level": 0}, "energy_rhythm": "", "top_strengths": [], "growth_targets": [], "checkin_cadence": "", "confidence_band": "low", "near_term_focus": [], "conflict_posture": "", "connection_style": "", "stress_level_now": 0, "summary_one_liner": "Bilinmezlikler ve eksik bilgilerle dolu bir değerlendirme.", "social_action_style": "", "soothing_strategies": [], "support_circle_size": 0, "time_budget_hours_weekly": 0}	2025-08-20 00:52:25.247366+03	2025-08-20 00:52:25.247366+03
\.


--
-- Data for Name: user_subscriptions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_subscriptions (id, user_id, plan_id, status, billing_cycle, start_date, end_date, created_at, updated_at, credits_used, credits_remaining, is_primary, iap_transaction_id) FROM stdin;
2dd37537-8a71-44aa-a22c-8722c0f9b524	ebe6eee2-01ae-4753-9737-0983b0330880	extra	active	monthly	2025-08-19 22:38:45.373423	2025-09-19 22:38:45.373423	2025-08-19 22:38:45.373423	2025-08-19 22:38:45.373423	{}	{"other_analysis": 25, "coaching_tokens": 500000000, "self_reanalysis": 5, "relationship_analysis": 25}	f	\N
bc822d05-6b7d-4d42-a7da-680c386882c7	ebe6eee2-01ae-4753-9737-0983b0330880	standard	active	monthly	2025-08-19 22:19:40.282202	2025-09-19 22:19:40.281	2025-08-19 22:19:40.282202	2025-08-19 22:41:11.695497	{}	{"other_analysis": 8, "coaching_tokens": 200000000, "self_reanalysis": 2, "relationship_analysis": 8}	f	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, email, locale, created_at) FROM stdin;
ebe6eee2-01ae-4753-9737-0983b0330880	test@test.com	tr	2025-08-19 20:39:47.570899+03
5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	realtest@test.com	\N	2025-08-20 22:59:23.023997+03
2a1881bf-51c8-4726-ad0e-4206633e351d	test@example.com	\N	2025-08-20 23:08:29.82366+03
f55dfb24-6a6e-495d-86c7-897a73ffcb88	verify@test.com	\N	2025-08-20 23:10:50.292774+03
\.


--
-- Name: responses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.responses_id_seq', 1, false);


--
-- Name: analysis_results analysis_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis_results
    ADD CONSTRAINT analysis_results_pkey PRIMARY KEY (id);


--
-- Name: assessments assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (id);


--
-- Name: chat_sessions chat_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_sessions
    ADD CONSTRAINT chat_sessions_pkey PRIMARY KEY (id);


--
-- Name: dyad_scores dyad_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dyad_scores
    ADD CONSTRAINT dyad_scores_pkey PRIMARY KEY (id);


--
-- Name: dyads dyads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dyads
    ADD CONSTRAINT dyads_pkey PRIMARY KEY (id);


--
-- Name: iap_products iap_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iap_products
    ADD CONSTRAINT iap_products_pkey PRIMARY KEY (id);


--
-- Name: iap_products iap_products_platform_product_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iap_products
    ADD CONSTRAINT iap_products_platform_product_id_key UNIQUE (platform, product_id);


--
-- Name: iap_purchases iap_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iap_purchases
    ADD CONSTRAINT iap_purchases_pkey PRIMARY KEY (id);


--
-- Name: iap_purchases iap_purchases_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iap_purchases
    ADD CONSTRAINT iap_purchases_transaction_id_key UNIQUE (transaction_id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: language_incidents language_incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language_incidents
    ADD CONSTRAINT language_incidents_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: monthly_usage_summary monthly_usage_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_usage_summary
    ADD CONSTRAINT monthly_usage_summary_pkey PRIMARY KEY (id);


--
-- Name: monthly_usage_summary monthly_usage_summary_user_id_month_year_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_usage_summary
    ADD CONSTRAINT monthly_usage_summary_user_id_month_year_key UNIQUE (user_id, month_year);


--
-- Name: payg_pricing payg_pricing_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payg_pricing
    ADD CONSTRAINT payg_pricing_pkey PRIMARY KEY (id);


--
-- Name: payg_purchases payg_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payg_purchases
    ADD CONSTRAINT payg_purchases_pkey PRIMARY KEY (id);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: responses responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responses
    ADD CONSTRAINT responses_pkey PRIMARY KEY (id);


--
-- Name: scores scores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_pkey PRIMARY KEY (id);


--
-- Name: subscription_plans subscription_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_plans
    ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (id);


--
-- Name: token_costs token_costs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_costs
    ADD CONSTRAINT token_costs_pkey PRIMARY KEY (id);


--
-- Name: usage_tracking usage_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usage_tracking
    ADD CONSTRAINT usage_tracking_pkey PRIMARY KEY (id);


--
-- Name: user_lifecoaching_notes user_lifecoaching_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lifecoaching_notes
    ADD CONSTRAINT user_lifecoaching_notes_pkey PRIMARY KEY (user_id);


--
-- Name: user_subscriptions user_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_analysis_results_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_analysis_results_created_at ON public.analysis_results USING btree (created_at DESC);


--
-- Name: idx_analysis_results_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_analysis_results_status ON public.analysis_results USING btree (status);


--
-- Name: idx_analysis_results_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_analysis_results_user_id ON public.analysis_results USING btree (user_id);


--
-- Name: idx_iap_transaction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_iap_transaction ON public.iap_purchases USING btree (transaction_id);


--
-- Name: idx_iap_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_iap_user ON public.iap_purchases USING btree (user_id);


--
-- Name: idx_lifecoaching_notes_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lifecoaching_notes_user_id ON public.user_lifecoaching_notes USING btree (user_id);


--
-- Name: idx_monthly_usage_user_month; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_monthly_usage_user_month ON public.monthly_usage_summary USING btree (user_id, month_year);


--
-- Name: idx_payg_purchases_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_payg_purchases_user_id ON public.payg_purchases USING btree (user_id);


--
-- Name: idx_people_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_people_user ON public.people USING btree (user_id);


--
-- Name: idx_resp_assessment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_resp_assessment ON public.responses USING btree (assessment_id);


--
-- Name: idx_resp_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_resp_item ON public.responses USING btree (item_id);


--
-- Name: idx_usage_tracking_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usage_tracking_created_at ON public.usage_tracking USING btree (created_at);


--
-- Name: idx_usage_tracking_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usage_tracking_user_id ON public.usage_tracking USING btree (user_id);


--
-- Name: idx_user_subscriptions_end_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_subscriptions_end_date ON public.user_subscriptions USING btree (end_date);


--
-- Name: idx_user_subscriptions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_subscriptions_status ON public.user_subscriptions USING btree (status);


--
-- Name: idx_user_subscriptions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_subscriptions_user_id ON public.user_subscriptions USING btree (user_id);


--
-- Name: usage_tracking trigger_update_monthly_usage; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_monthly_usage AFTER INSERT ON public.usage_tracking FOR EACH ROW EXECUTE FUNCTION public.update_monthly_usage();


--
-- Name: usage_tracking update_monthly_usage_on_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_monthly_usage_on_insert AFTER INSERT ON public.usage_tracking FOR EACH ROW EXECUTE FUNCTION public.update_monthly_usage_summary();


--
-- Name: analysis_results analysis_results_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.analysis_results
    ADD CONSTRAINT analysis_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: assessments assessments_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: chat_sessions chat_sessions_dyad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_sessions
    ADD CONSTRAINT chat_sessions_dyad_id_fkey FOREIGN KEY (dyad_id) REFERENCES public.dyads(id) ON DELETE CASCADE;


--
-- Name: dyad_scores dyad_scores_dyad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dyad_scores
    ADD CONSTRAINT dyad_scores_dyad_id_fkey FOREIGN KEY (dyad_id) REFERENCES public.dyads(id) ON DELETE CASCADE;


--
-- Name: dyads dyads_a_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dyads
    ADD CONSTRAINT dyads_a_person_id_fkey FOREIGN KEY (a_person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: dyads dyads_b_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dyads
    ADD CONSTRAINT dyads_b_person_id_fkey FOREIGN KEY (b_person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: user_subscriptions fk_iap_transaction; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT fk_iap_transaction FOREIGN KEY (iap_transaction_id) REFERENCES public.iap_purchases(transaction_id);


--
-- Name: payg_purchases fk_payg_iap_transaction; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payg_purchases
    ADD CONSTRAINT fk_payg_iap_transaction FOREIGN KEY (iap_transaction_id) REFERENCES public.iap_purchases(transaction_id);


--
-- Name: iap_purchases iap_purchases_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.iap_purchases
    ADD CONSTRAINT iap_purchases_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: language_incidents language_incidents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.language_incidents
    ADD CONSTRAINT language_incidents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: messages messages_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.chat_sessions(id) ON DELETE CASCADE;


--
-- Name: monthly_usage_summary monthly_usage_summary_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_usage_summary
    ADD CONSTRAINT monthly_usage_summary_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.user_subscriptions(id);


--
-- Name: monthly_usage_summary monthly_usage_summary_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.monthly_usage_summary
    ADD CONSTRAINT monthly_usage_summary_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: people people_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reports reports_dyad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_dyad_id_fkey FOREIGN KEY (dyad_id) REFERENCES public.dyads(id) ON DELETE CASCADE;


--
-- Name: reports reports_owner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: responses responses_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responses
    ADD CONSTRAINT responses_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: responses responses_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.responses
    ADD CONSTRAINT responses_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: scores scores_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: usage_tracking usage_tracking_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usage_tracking
    ADD CONSTRAINT usage_tracking_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.user_subscriptions(id);


--
-- Name: usage_tracking usage_tracking_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usage_tracking
    ADD CONSTRAINT usage_tracking_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_lifecoaching_notes user_lifecoaching_notes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_lifecoaching_notes
    ADD CONSTRAINT user_lifecoaching_notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_subscriptions user_subscriptions_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.subscription_plans(id);


--
-- Name: user_subscriptions user_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

