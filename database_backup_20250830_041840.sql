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

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: get_user_active_subscriptions(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_user_active_subscriptions(p_user_id text) RETURNS TABLE(id text, subscription_id text, plan_id text, start_date timestamp without time zone, end_date timestamp without time zone, status text, credits_remaining jsonb, is_primary boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        us.id::TEXT,
        us.id::TEXT as subscription_id,
        us.plan_id,
        us.start_date,
        us.end_date,
        us.status,
        us.credits_remaining,
        us.is_primary
    FROM user_subscriptions us
    WHERE us.user_id::TEXT = p_user_id 
        AND (us.status = 'active' OR us.status = 'cancelled')
        AND (us.end_date IS NULL OR us.end_date > NOW())
    ORDER BY 
        us.end_date ASC NULLS LAST,
        us.created_at ASC;
END;
$$;


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
-- Name: is_coupon_valid(character varying, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_coupon_valid(p_code character varying, p_user_id uuid) RETURNS TABLE(valid boolean, message text, coupon_data jsonb)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_coupon RECORD;
    v_usage_count INTEGER;
BEGIN
    -- Get coupon details
    SELECT * INTO v_coupon
    FROM coupons
    WHERE UPPER(code) = UPPER(p_code)
      AND is_active = true;
    
    -- Check if coupon exists
    IF v_coupon IS NULL THEN
        RETURN QUERY SELECT 
            false, 
            'Kupon kodu bulunamadı'::TEXT,
            NULL::JSONB;
        RETURN;
    END IF;
    
    -- Check validity dates
    IF v_coupon.valid_from > NOW() THEN
        RETURN QUERY SELECT 
            false, 
            'Kupon henüz aktif değil'::TEXT,
            NULL::JSONB;
        RETURN;
    END IF;
    
    IF v_coupon.valid_until IS NOT NULL AND v_coupon.valid_until < NOW() THEN
        RETURN QUERY SELECT 
            false, 
            'Kupon süresi dolmuş'::TEXT,
            NULL::JSONB;
        RETURN;
    END IF;
    
    -- Check max uses
    IF v_coupon.max_uses IS NOT NULL AND v_coupon.uses_count >= v_coupon.max_uses THEN
        RETURN QUERY SELECT 
            false, 
            'Kupon kullanım limiti dolmuş'::TEXT,
            NULL::JSONB;
        RETURN;
    END IF;
    
    -- Check if user has already used this coupon (for one-time use coupons)
    IF v_coupon.one_time_per_user THEN
        SELECT COUNT(*) INTO v_usage_count
        FROM coupon_usage
        WHERE coupon_id = v_coupon.id AND user_id = p_user_id;
        
        IF v_usage_count > 0 THEN
            RETURN QUERY SELECT 
                false, 
                'Bu kuponu daha önce kullandınız'::TEXT,
                NULL::JSONB;
            RETURN;
        END IF;
    END IF;
    
    -- Coupon is valid
    RETURN QUERY SELECT 
        true,
        'Kupon geçerli'::TEXT,
        to_jsonb(v_coupon);
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
    metadata jsonb,
    form1_data jsonb,
    form2_data jsonb,
    form3_data jsonb,
    result_blocks jsonb,
    updated_at timestamp without time zone DEFAULT now()
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
-- Name: COLUMN analysis_results.result_blocks; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.analysis_results.result_blocks IS 'Parsed markdown content split into blocks by main headings for better readability';


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
-- Name: coupon_usage; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coupon_usage (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    coupon_id uuid,
    user_id uuid,
    used_at timestamp with time zone DEFAULT now(),
    subscription_id uuid
);


--
-- Name: coupons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coupons (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code character varying(50) NOT NULL,
    description text,
    type character varying(50) NOT NULL,
    plan_id character varying(50),
    duration_months integer DEFAULT 1,
    discount_percent integer,
    credit_amount integer,
    credit_type character varying(50),
    max_uses integer,
    uses_count integer DEFAULT 0,
    one_time_per_user boolean DEFAULT true,
    valid_from timestamp with time zone DEFAULT now(),
    valid_until timestamp with time zone,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT coupons_discount_percent_check CHECK (((discount_percent >= 0) AND (discount_percent <= 100))),
    CONSTRAINT coupons_type_check CHECK (((type)::text = ANY (ARRAY[('free_subscription'::character varying)::text, ('discount'::character varying)::text, ('credit'::character varying)::text])))
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
    test_type character varying(50),
    text_en text,
    options_en text,
    conditional_on character varying(255)
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
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    total_analysis_credits integer DEFAULT 0
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
-- Name: token_packages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.token_packages (
    id text NOT NULL,
    package_size text NOT NULL,
    token_amount integer NOT NULL,
    price_usd numeric(10,2) NOT NULL,
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
    iap_transaction_id character varying(255),
    coupon_id uuid
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

COPY public.analysis_results (id, user_id, analysis_type, status, s0_data, s1_data, result_markdown, lifecoaching_notes, error_message, retry_count, created_at, completed_at, metadata, form1_data, form2_data, form3_data, result_blocks, updated_at) FROM stdin;
1ee06ddc-4e15-4bb1-b2c0-d0fdbb3bd3f9	5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	self	completed	{"S0_AGE": 28, "S0_GENDER": "Erkek", "S0_HOBBIES": "Kitap okuma, yüzme, doğa yürüyüşü", "S0_LIFE_GOAL": "Kendi işimi kurmak ve finansal özgürlüğe ulaşmak", "S0_TOP_CHALLENGES": "İş-yaşam dengesi ve stres yönetimi"}	{"S1_BF_C1": 5, "S1_BF_E1": 2, "S1_BF_O1": 4, "S1_MB_FC1": "B", "S1_OE_HAPPY": "Üniversiteden mezun olduğum gün", "S1_DISC_SJT1": 0, "S1_OE_STRENGTHS": "Analitik düşünme, sorumluluk, hızlı öğrenme"}	Hazır mısınız? Başlayalım..\n\nGerektiğinde keskin olabilirim. Dünyayı okuma biçimim özür dilemeksizin doğrudandır. Amacım sizi daha güçlü ve daha mutlu kılmaktır; bu yüzden zaman zaman sizi sert bir şekilde eleştireceğim - asla sizi küçümsemek için değil, her zaman sizi gerçekliğe demirlemek için.\n\n| Özellik / Boyut | Puan |\n|------------------------------------|-----------------|\n| **MBTI Tipi** | Yetersiz veri |\n| MBTI Dışadönüklük (E) | Yetersiz veri |\n| MBTI İçedönüklük (I) | Yetersiz veri |\n| MBTI Duyumsama (S) | Yetersiz veri |\n| MBTI Sezgi (N) | Yetersiz veri |\n| MBTI Düşünme (T) | Yetersiz veri |\n| MBTI Hissetme (F) | Yetersiz veri |\n| MBTI Yargılama (J) | Yetersiz veri |\n| MBTI Algılama (P) | Yetersiz veri |\n| **Beş Faktör - Deneyime Açıklık (O)** | 75% |\n| **Beş Faktör - Sorumluluk (C)** | 100% |\n| **Beş Faktör - Dışadönüklük (E)** | 25% |\n| **Beş Faktör - Uyumluluk (A)** | Yetersiz veri |\n| **Beş Faktör - Duygusal Denge (N)** | Yetersiz veri |\n| **DISC - Hakimiyet (D)** | Yetersiz veri |\n| **DISC - Etki (I)** | Yetersiz veri |\n| **DISC - Kararlılık (S)** | Yetersiz veri |\n| **DISC - Uyum (C)** | Yetersiz veri |\n| Bağlanma - Kaygı | Yetersiz veri |\n| Bağlanma - Kaçınma | Yetersiz veri |\n| Çatışma Stili (Birincil) | Yetersiz veri |\n| Duygu Düzenleme - Yeniden Değerlendirme | Yetersiz veri |\n| Duygu Düzenleme - Bastırma | Yetersiz veri |\n| Empati - Duygusal İlgi | Yetersiz veri |\n| Empati - Perspektif Alma | Yetersiz veri |\n\n## Temel Kişiliğiniz\n\nAnaliziniz, son derece **disiplinli, hedef odaklı ve içe dönük** bir yapıya işaret ediyor. Kişiliğinizin temel direği, **Sorumluluk (Conscientiousness)** boyutundaki olağanüstü yüksek (%100) puandır. Bu, sizi doğal olarak organize, güvenilir ve görevlerini sonuna kadar takip eden biri yapar. Bir işe başladığınızda, onu en yüksek standartlarda bitirme eğilimindesiniz. Bu, hem en büyük gücünüz hem de en önemli risk alanınızdır.\n\n**Dışadönüklük (Extraversion)** puanınızın (%25) düşük olması, enerjinizi dış dünyadan ve sosyal etkileşimlerden ziyade kendi iç dünyanızdan, düşüncelerinizden ve odaklandığınız projelerden aldığınızı gösteriyor. Bu, sizi kalabalıklar içinde veya sürekli sosyal etkileşim gerektiren ortamlarda hızla yorulan biri yapar. Derinlemesine düşünmeyi, yalnız çalışmayı ve anlamlı, bire bir ilişkileri yüzeysel sosyal bağlara tercih edersiniz.\n\n**Deneyime Açıklık (Openness)** puanınızın (%75) oldukça yüksek olması, bu yapılandırılmış ve içe dönük doğanıza entelektüel bir merak ve esneklik katıyor. Yeni fikirleri, soyut kavramları ve farklı bakış açılarını keşfetmekten hoşlanırsınız. Bu, sizi katı bir uygulayıcı olmaktan çıkarıp, kendi alanınızda yenilikçi ve stratejik düşünebilen birine dönüştürür. Kendi kendinize "Analitik düşünme" ve "hızlı öğrenme" yeteneklerinizi atfetmeniz bu özellikle tamamen uyumludur.\n\nÖzetle, profiliniz, büyük hedeflere ulaşmak için gereken içsel motoru ve disiplini taşıyan, ancak bu hedeflere giden yolda sosyal enerji yönetimi ve mükemmeliyetçilikle mücadele etmesi gereken bir stratejist ve uygulayıcıyı tanımlıyor.\n\n## Güçlü Yönleriniz\n\nVerileriniz, somut ve pratik avantajlar sağlayan birkaç temel gücü ortaya koyuyor. Bunlar, üzerinde kariyer ve kişisel tatmin inşa edebileceğiniz temel taşlarıdır.\n\n*   **Sarsılmaz Sorumluluk ve Güvenilirlik:** %100 Sorumluluk puanınız, sözlerinizin ve taahhütlerinizin sağlam olduğunu gösterir. Bir görev size verildiğinde, o görevin tamamlanacağı ve yüksek kalitede yapılacağı konusunda insanlar size güvenir. Bu, profesyonel ortamlarda sizi paha biçilmez kılar ve uzun vadeli projelerde başarı için kritik bir temel oluşturur. Kendi işinizi kurma hedefinizde, bu özellik iş ahlakınızın ve marka itibarınızın temelini oluşturacaktır.\n\n*   **Derin Odaklanma ve Bağımsız Çalışma Yeteneği:** Düşük dışadönüklük, dikkatinizin dağılmasını önleyen bir kalkan görevi görür. Dış uyaranlara daha az ihtiyaç duyduğunuz için, karmaşık sorunları çözmek veya uzun saatler boyunca konsantrasyon gerektiren işleri tamamlamak için derinlemesine odaklanabilirsiniz. Bu, özellikle strateji geliştirme, kodlama, yazma veya herhangi bir analitik çalışma için muazzam bir avantajdır.\n\n*   **Analitik ve Stratejik Zeka:** Yüksek Deneyime Açıklık, sizi sadece görevleri yerine getiren biri yapmaz; aynı zamanda "neden" ve "nasıl daha iyi olabilir" sorularını soran biri yapar. Kalıpları görme, verileri analiz etme ve gelecekteki olasılıkları planlama yeteneğiniz güçlüdür. Kendi belirttiğiniz "analitik düşünme" gücü, bu özelliğin bir yansımasıdır ve iş kurma hedefinizde pazar analizi ve stratejik planlama gibi alanlarda size üstünlük sağlayacaktır.\n\n*   **Hızlı Öğrenme ve Zihinsel Esneklik:** Yeni fikirlere açık olmanız, yeni becerileri hızla edinmenizi sağlar. Statükoya meydan okumaktan ve daha verimli yollar aramaktan çekinmezsiniz. Bu, özellikle hızla değişen bir sektörde kendi işinizi kurarken kritik bir hayatta kalma becerisidir. Bir soruna takılıp kalmak yerine, yeni yaklaşımlar öğrenip adapte olabilirsiniz.\n\n## Kör Noktalar ve Riskler\n\nGüçlü yönlerinizin kaçınılmaz birer gölgesi vardır. Bu riskleri anlamak, onları yönetmenin ilk adımıdır. Bunları görmezden gelmek, eninde sonunda hedeflerinize ulaşmanızı engelleyecektir.\n\n*   **Mükemmeliyetçilik ve Tükenmişlik Sendromu:** %100 Sorumluluk, "yeterince iyi" kavramını kabul etmeyi zorlaştırır. Bu durum, sizi sürekli daha fazlasını yapmaya, detaylarda boğulmaya ve dinlenmeyi bir lüks olarak görmeye itebilir. Kendi belirttiğiniz "iş-yaşam dengesi ve stres yönetimi" zorluğu doğrudan bu kör noktadan kaynaklanmaktadır. Bu yolda devam ederseniz, tükenmişlik sadece bir risk değil, neredeyse matematiksel bir kesinliktir.\n\n*   **Sosyal Geri Çekilme ve Ağ Kurmada Zorluk:** İçe dönük yapınız, özellikle kendi işinizi kurma gibi dışa dönük eylemler gerektiren bir hedefle birleştiğinde bir engele dönüşebilir. Potansiyel müşterilerle, yatırımcılarla veya ortaklarla ilişki kurmak için gereken sosyal enerjiye sahip olmayabilirsiniz. Bu, dünyanın en iyi ürününü veya hizmetini yaratsanız bile, kimsenin bundan haberi olmaması riskini doğurur.\n\n*   **Eleştiriye Aşırı Duyarlılık ve Savunmacılık:** Yaptığınız işe bu kadar yüksek standartlar ve kişisel yatırım koyduğunuzda, eleştiriyi kişisel bir saldırı olarak algılama eğiliminiz olabilir. Mükemmeliyetçiliğiniz, herhangi bir hatanın veya olumsuz geri bildirimin benlik saygınıza bir darbe gibi gelmesine neden olabilir. Bu, öğrenme ve büyüme için gerekli olan yapıcı geri bildirimleri kabul etmenizi zorlaştırabilir.\n\n*   **Delegasyon Yapamama:** "En iyisini ben yaparım" düşüncesi, yüksek Sorumluluk sahibi kişilerin yaygın bir tuzağıdır. Başkalarına görev vermekte zorlanabilir, her detayı kontrol etme ihtiyacı hissedebilirsiniz. Kendi işinizi kurarken bu, büyümenizin önündeki en büyük engel olacaktır. Tek başınıza her şeyi yapmaya çalışmak, sizi darboğaza sokar ve işinizin ölçeklenmesini imkansız hale getirir.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişkilerde, muhtemelen **güvenilir, sadık ve istikrarlı** bir partner olarak algılanıyorsunuz. Sözlerinizi tutar, sorumluluklarınızı yerine getirirsiniz. Ancak, içe dönük doğanız, duygusal ihtiyaçlarınızı veya düşüncelerinizi sözlü olarak sık sık ifade etmediğiniz anlamına gelebilir. Partneriniz, sizin sevginizi ve bağlılığınızı eylemlerinizden (sorumluluklarınızı yerine getirme, destek olma) anlamak zorundadır, çünkü bunu sık sık duymayabilir.\n\nBu durum, daha dışa dönük veya duygusal olarak ifadeci bir partnere sahipseniz çatışmaya yol açabilir. Onlar daha fazla sözlü teyit, sosyal aktivite ve spontanlık beklerken, siz huzuru ve sessizliği tercih edebilirsiniz. Sizin için "kaliteli zaman", birlikte sessizce bir aktivite yapmak olabilirken, partneriniz için bu, derin bir sohbet veya sosyal bir etkinliğe katılmak anlamına gelebilir.\n\nArkadaşlıklarınız muhtemelen az sayıda ama derindir. Yüzeysel sohbetlerden ve büyük gruplardan kaçınır, entelektüel veya ortak ilgi alanlarına dayalı güçlü bağlar kurarsınız. Arkadaşlarınız, zor zamanlarda güvenebilecekleri, mantıklı tavsiyeler veren biri olduğunuzu bilirler. Ancak, sosyal etkinlikleri başlatan veya grubu bir araya getiren kişi olma olasılığınız düşüktür.\n\n## Kariyer ve Çalışma Tarzı\n\nKariyer yolunuzda, "Kendi işimi kurmak ve finansal özgürlüğe ulaşmak" hedefi, kişiliğinizle hem mükemmel bir uyum hem de ciddi bir çelişki içindedir.\n\n**Uyumlu Yönler:** Yüksek Sorumluluk, bir iş kurmak için gereken özveri, disiplin ve uzun saatler çalışma yeteneğini size doğal olarak verir. Planlama, organize etme ve bir vizyonu somut adımlara dökme konusunda mükemmelsiniz. Yüksek Deneyime Açıklık, pazarınızdaki yenilikleri takip etmenizi ve stratejik olarak uyum sağlamanızı sağlar. Bağımsız çalışma yeteneğiniz, işin ilk aşamalarında tek başınıza ilerlemenizi kolaylaştırır.\n\n**Çelişkili Yönler:** Girişimcilik, acımasız bir şekilde sosyal bir faaliyettir. Satış yapmanız, pazarlık etmeniz, ağ kurmanız, ekibinizi motive etmeniz ve vizyonunuzu başkalarına satmanız gerekir. Düşük Dışadönüklük, bu alanların her birini sizin için doğal olmayan ve enerji tüketen faaliyetlere dönüştürür. En büyük zorluğunuz ürün veya hizmeti geliştirmek değil, onu dünyaya duyurmak ve satmak olacaktır.\n\nBu çelişkiyi yönetmek için iki yol vardır: Ya bu becerileri bilinçli bir şekilde geliştirmek için kendinizi zorlarsınız (ki bu yorucu olacaktır) ya da bu alanlarda güçlü olan bir ortak bulursunuz. Sizin teknik ve stratejik beyninizle, dışa dönük bir ortağın sosyal ve satış becerilerini birleştirmek, başarı şansınızı katlayacaktır.\n\n## Duygusal Desenler ve Stres\n\nStresle başa çıkma yönteminiz, muhtemelen içselleştirme ve problem çözme odaklıdır. Bir sorunla karşılaştığınızda, duygusal bir patlama yaşamak yerine, sorunu analiz etmeye ve mantıklı bir çözüm bulmaya çalışırsınız. Bu genellikle etkilidir, ancak çözülemeyen veya kontrolünüz dışındaki sorunlarla karşılaştığınızda, bu içselleştirme süreci ruminasyona (aynı olumsuz düşünceleri tekrar tekrar zihinde evirip çevirme) dönüşebilir.\n\nStresinizin ana kaynağı, kendi kendinize koyduğunuz yüksek standartlardır. Bir hedefe ulaşamadığınızda veya bir hata yaptığınızda, en sert eleştirmeniniz kendiniz olursunuz. Bu, benlik saygınızı doğrudan başarı ve üretkenliğe bağlama riskini taşır. Başarısızlık, sadece bir sonuç değil, kişisel bir kusur gibi hissedilebilir.\n\nBelirttiğiniz "stres yönetimi" zorluğu, bu içsel baskı mekanizmasının bir sonucudur. Fiziksel aktiviteler (yüzme, doğa yürüyüşü gibi hobileriniz) bu birikmiş stresi atmak için mükemmel kanallardır, çünkü sizi zihninizden çıkarıp bedeninize odaklanmaya zorlarlar. Bu aktiviteleri bir lüks olarak değil, zihinsel sağlığınız için bir zorunluluk olarak görmelisiniz.\n\n## Yaşam Desenleri ve Muhtemel Tuzaklar\n\nMevcut profilinizle, hayatınız boyunca muhtemelen istikrarlı ve ölçülebilir başarılar elde etme eğiliminde olacaksınız. Kariyerinizde adım adım yükselecek, hedeflerinize metodik bir şekilde ulaşacaksınız. Ancak dikkat etmeniz gereken birkaç muhtemel tuzak var:\n\n*   **"Ne Zaman Yeterli Olacak?" Tuzağı:** Yüksek Sorumluluk, hedeflere ulaştığınızda bile tatmin olmayı zorlaştırabilir. Bir zirveye ulaştığınızda, kutlamak yerine hemen bir sonraki daha yüksek zirveyi gözünüze kestirebilirsiniz. Bu, sürekli bir koşu bandında olma hissine yol açar ve "finansal özgürlüğe" ulaşsanız bile, zihinsel olarak asla "özgür" hissetmemenize neden olabilir.\n\n*   **İlişkileri İhmal Etme Riski:** İşinize ve hedeflerinize o kadar odaklanabilirsiniz ki, kişisel ilişkilerinizin gerektirdiği zamanı ve enerjiyi ayırmayı unutabilirsiniz. İlişkiler, bir proje gibi yönetilemez; sürekli bakım ve duygusal yatırım gerektirirler. Bu dengeyi kuramazsanız, profesyonel olarak başarılı ama kişisel olarak yalnız kalma riskiyle karşı karşıya kalırsınız.\n\n*   **Spontanlığı ve Oyunu Kaybetme:** Hayatınız aşırı planlı ve yapılandırılmış hale gelebilir. Plansız bir gün geçirme, sadece anın tadını çıkarma veya "üretken olmayan" bir hobiyle uğraşma fikri size rahatsız edici gelebilir. Bu, hayatın neşesini ve yaratıcılığını besleyen spontan anları kaçırmanıza neden olur.\n\n## Uygulanabilir İleriye Dönük Yol\n\nAşağıdakiler, potansiyelinizi en üst düzeye çıkarırken risklerinizi yönetmenize yardımcı olacak somut, davranışsal adımlardır.\n\n*   **"Yeterince İyi" Prensibini Benimseyin:** Her görev için kendinize sorun: "Bu işin %80'lik kalitede tamamlanması yeterli mi?" Çoğu zaman cevap evet olacaktır. Mükemmeliyetçiliği, yalnızca gerçekten önemli olan %20'lik görevlere saklayın. Bu, enerjinizi korumanıza ve tükenmişliği önlemenize yardımcı olacaktır.\n\n*   **Takviminize "Hiçbir Şey Yapmama" Zamanı Ekleyin:** Tıpkı bir iş toplantısı gibi, takviminize haftada en az iki saatlik "boş zaman" blokları ekleyin. Bu süre zarfında işle ilgili hiçbir şey düşünmek, plan yapmak veya üretmek yasaktır. Bu, dinlenmenin pazarlık edilemez bir öncelik olduğunu beyninize öğretmenize yardımcı olacaktır.\n\n*   **Yapılandırılmış Sosyalleşme Planı Oluşturun:** Sosyalleşme enerjinizi tükettiği için, onu bir görev gibi ele alın. Ayda bir veya iki tane, sizin için önemli olan ağ kurma etkinliği veya sosyal buluşma belirleyin. Bu etkinliklere hazırlıklı gidin (kiminle konuşmak istediğiniz gibi) ve enerji seviyeniz düştüğünde ayrılmak için kendinize izin verin.\n\n*   **Tamamlayıcı Bir Ortak Arayın:** Kendi işinizi kurma hedefinizde ciddiyken, aktif olarak sizin zayıf yönlerinizi tamamlayan bir ortak arayın. Siz ürün, strateji ve operasyonlara odaklanırken, satış, pazarlama ve insan ilişkilerinde güçlü, dışa dönük birini bulun. Bu, başarı şansınızı logaritmik olarak artırır.\n\n*   **Fiziksel Sınırlar Koyun:** İş gününüzün ne zaman başlayıp ne zaman bittiğine dair net kurallar belirleyin. Akşam saat 8'den sonra iş e-postalarını kontrol etmemek veya hafta sonları bir tam günü tamamen işten uzak geçirmek gibi. Fiziksel olarak işten ayrılmak, zihinsel olarak da ayrılmanıza yardımcı olur.\n\n*   **"Başarısızlık Özgeçmişi" Tutun:** Bir kağıda veya dosyaya, geçmişte yaşadığınız başarısızlıkları, hataları ve yanlış adımları yazın. Her birinin yanına, o deneyimden ne öğrendiğinizi ve o başarısızlığa rağmen nasıl hayatta kaldığınızı not edin. Bu, başarısızlığın son değil, bir veri noktası olduğunu anlamanıza yardımcı olur.\n\n*   **Delegasyon Alıştırması Yapın:** Küçük, düşük riskli görevlerle başlayarak başkalarına iş vermeye başlayın. Örneğin, bir sanal asistana randevularınızı düzenletmek gibi. Görevin mükemmel yapılmasa bile dünyanın sonunun gelmediğini görmek, daha büyük sorumlulukları devretme konusunda size güven verecektir.\n\n*   **Geri Bildirimi Kişiselleştirmeyin:** Birisi işinizle ilgili eleştiride bulunduğunda, bunu bir veri olarak kabul etme pratiği yapın. "Bu geri bildirimde işime yarayacak bir doğruluk payı var mı?" diye sorun. Cevap evet ise, kullanın. Hayır ise, atın. Geri bildirimi karakterinize bir saldırı olarak değil, projenize bir hediye olarak görmeye çalışın.\n\n## Kendi Sözlerinizden: Anılar ve Anlam\n\nKendi ifadeleriniz, test sonuçlarının ortaya koyduğu tabloyu doğruluyor ve ona derinlik katıyor. Bu kelimeler, sizin motivasyonlarınızın ve zorluklarınızın ham halidir.\n\nEn mutlu anınız olarak **"Üniversiteden mezun olduğum gün"** demeniz son derece anlamlıdır. Bu, sosyal bir olay, bir ilişki anı veya spontane bir macera değil; uzun vadeli, zorlu bir hedefin başarıyla tamamlanmasıdır. Bu, ödül sisteminizin **başarı ve tamamlanma** üzerine kurulu olduğunu gösteriyor. Sizi en çok neyin motive ettiğini anlamak için bundan daha net bir kanıt olamaz: zor bir işi alıp sonuca ulaştırmak.\n\nHayattaki ana hedefiniz **"Kendi işimi kurmak ve finansal özgürlüğe ulaşmak"**. Bu, mezuniyet anınızdaki tatmin duygusunu hayatınızın tamamına yayma arzusudur. Bu sadece para kazanmakla ilgili bir hedef değil; kontrol, özerklik ve kendi standartlarınıza göre bir şeyler inşa etme arzusudur. Bu, yüksek Sorumluluk özelliğinizin doğal bir uzantısıdır.\n\nEn büyük zorluğunuz olarak **"İş-yaşam dengesi ve stres yönetimi"**ni belirtmeniz, bu hedefe giden yoldaki en büyük engeli gördüğünüzü gösteriyor. Bu, içgörünüzün yüksek olduğunu kanıtlar. Motorunuzun ne kadar güçlü olduğunu biliyorsunuz, ama aynı zamanda bu motorun aşırı ısınma riskini de hissediyorsunuz.\n\nKendinizde gördüğünüz güçlü yönler - **"Analitik düşünme, sorumluluk, hızlı öğrenme"** - kişilik analiziyle bire bir örtüşüyor. Bu, kendinizi oldukça doğru bir şekilde tanıdığınızı gösterir. Sorun öz-farkındalık eksikliği değil, bu bilgiyi davranışa dökme ve kör noktaları yönetme konusundaki strateji eksikliğidir. Bu rapor, tam olarak bu stratejiyi sağlamayı amaçlamaktadır.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, psikolojide onlarca yıldır geçerliliği kanıtlanmış bilimsel modellere dayanmaktadır. Vardığımız sonuçlar, keyfi yorumlar değil, kişilik bilimi alanındaki sağlam araştırmaların bir sentezidir.\n\nTemel çerçevemiz, **Beş Faktör Kişilik Modeli**'dir (genellikle OCEAN olarak bilinir). Bu model, kişiliği beş geniş boyutta (Deneyime Açıklık, Sorumluluk, Dışadönüklük, Uyumluluk, Duygusal Denge) ele alır. Araştırmalar, bu özelliklerin iş performansı, ilişki tatmini, zihinsel sağlık ve hatta yaşam süresi gibi çok çeşitli yaşam sonuçlarını öngörebildiğini tutarlı bir şekilde göstermiştir. Sizin durumunuzda, özellikle yüksek Sorumluluk puanınız, akademik ve profesyonel başarı için güçlü bir öngörücüdür, ancak aynı zamanda mükemmeliyetçilik ve tükenmişlik riskini de beraberinde getirir. Düşük Dışadönüklük puanınız ise analitik rollerde başarıyı öngörürken, satış veya halkla ilişkiler gibi sosyal olarak yoğun rollerde zorluk yaşayabileceğinize işaret eder.\n\n**MBTI** ve **DISC** gibi diğer modeller, davranışsal tercihleri ve stilleri anlamak için faydalı çerçeveler sunar. MBTI, bilgi işleme ve karar verme şeklinize odaklanırken (örneğin, mantık mı yoksa değerler mi öncelikli), DISC daha çok gözlemlenebilir davranışsal eğilimlerinizi (örneğin, bir ekip içinde ne kadar iddialı veya destekleyici olduğunuz) tanımlar. Yanıtlarınız bu testlerin skorlarını hesaplamak için yeterli veri sağlamadığından, bu analizde bu modellere dayalı çıkarımlar yapmaktan kaçındık. Bu, varsayımlarda bulunmak yerine yalnızca eldeki somut kanıtlara bağlı kalma taahhüdümüzün bir parçasıdır.\n\nBu analizde sunulan öngörüler ve tavsiyeler, sizin gibi kişilik profillerine sahip bireylerin yaşam yollarında tekrar tekrar gözlemlenen kalıplara dayanmaktadır. Ancak unutmayın ki, kişilik bir kader değil, bir eğilimdir. Bu eğilimleri anlamak, size kendi yolunuzu daha bilinçli bir şekilde çizme, güçlü yönlerinizi en üst düzeye çıkarma ve risklerinizi proaktif olarak yönetme gücü verir.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilendirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-20 22:59:23.030584+03	2025-08-20 23:00:49.646929+03	{"language": "tr", "language_ok": true}	\N	\N	\N	\N	2025-08-29 20:45:13.649121
86d89883-2a2a-44e0-92db-78130b1da05d	5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	self	completed	{"S0_AGE": 28, "S0_GENDER": "Erkek", "S0_HOBBIES": "Kitap okuma, yüzme, doğa yürüyüşü", "S0_LIFE_GOAL": "Kendi işimi kurmak ve finansal özgürlüğe ulaşmak", "S0_TOP_CHALLENGES": "İş-yaşam dengesi ve stres yönetimi"}	{"S1_BF_C1": 5, "S1_BF_E1": 2, "S1_BF_O1": 4, "S1_MB_FC1": "B", "S1_OE_HAPPY": "Üniversiteden mezun olduğum gün", "S1_DISC_SJT1": 0, "S1_OE_STRENGTHS": "Analitik düşünme, sorumluluk, hızlı öğrenme"}	Hazır mısınız? Başlayalım..\n\nGerektiğinde sivri dilli olabilirim. Dünyayı okuma biçimim, özür dilemeyen bir netlik taşır. Amacım sizi daha güçlü ve mutlu kılmaktır; bu nedenle zaman zaman sizi sert bir şekilde eleştireceğim. Bunu sizi küçümsemek için değil, daima gerçeğe demirlemek için yapacağım.\n\n| Özellik / Boyut | Puan |\n|-------------------|-------|\n| **MBTI Tipi** | Yetersiz Veri |\n| MBTI Dışadönüklük (E) | 25% |\n| MBTI İçedönüklük (I) | 75% |\n| MBTI Duyumsama (S) | Yetersiz Veri |\n| MBTI Sezgi (N) | Yetersiz Veri |\n| MBTI Düşünme (T) | Yetersiz Veri |\n| MBTI Hissetme (F) | Yetersiz Veri |\n| MBTI Yargılama (J) | Yetersiz Veri |\n| MBTI Algılama (P) | Yetersiz Veri |\n| **Big Five - Deneyime Açıklık (O)** | 75% |\n| **Big Five - Sorumluluk (C)** | 100% |\n| **Big Five - Dışadönüklük (E)** | 25% |\n| **Big Five - Uyumluluk (A)** | Yetersiz Veri |\n| **Big Five - Duygusal Denge (N)** | Yetersiz Veri |\n| **DISC - Hakimiyet (D)** | Yetersiz Veri |\n| **DISC - Etkileme (I)** | Yetersiz Veri |\n| **DISC - Sadakat (S)** | Yetersiz Veri |\n| **DISC - Uygunluk (C)** | Yetersiz Veri |\n| Bağlanma - Kaygı | Yetersiz Veri |\n| Bağlanma - Kaçınma | Yetersiz Veri |\n| Çatışma Stili (Birincil) | Yetersiz Veri |\n| Duygu Düzenleme - Yeniden Değerlendirme | Yetersiz Veri |\n| Duygu Düzenleme - Bastırma | Yetersiz Veri |\n| Empati - Duygusal İlgi | Yetersiz Veri |\n| Empati - Perspektif Alma | Yetersiz Veri |\n\n**Önemli Not:** Bu analiz, verdiğiniz sınırlı yanıtlara dayanmaktadır. Özellikle kişilik testlerinin birçok boyutu için veri sağlanmamıştır. Bu nedenle, sonuçlar kişiliğinizin yalnızca belirli yönlerine dair bir ilk bakış sunar ve kapsamlı bir profil olarak görülmemelidir. Analiz, mevcut verileri kendi ifadelerinizle birleştirerek en anlamlı içgörüleri sunmaya odaklanacaktır.\n\n## Temel Kişilik Yapınız\n\nVerileriniz, son derece **sorumlu, disiplinli ve hedef odaklı** bir birey olduğunuzu gösteriyor. Sorumluluk (Conscientiousness) puanınızın en üst düzeyde olması, başladığınız işi bitirme, detaylara dikkat etme ve güvenilirlik gibi özelliklerin karakterinizin temelini oluşturduğuna işaret ediyor. Bu özellik, "kendi işimi kurma" hedefinizle mükemmel bir uyum içindedir. Başarıyı şansa bırakmayan, sistemli ve planlı hareket eden bir yapıdasınız.\n\nBununla birlikte, belirgin bir **içedönüklük** eğiliminiz var. Enerjinizi kalabalık sosyal ortamlardan ziyade yalnız kalarak veya küçük, anlamlı gruplar içinde yeniliyorsunuz. Bu, yüzeysel olmadığınız, aksine derinlemesine düşünmeye ve odaklanmaya ihtiyaç duyduğunuz anlamına gelir. Düşük dışadönüklük, sizi daha gözlemci, dikkatli ve bağımsız bir düşünür yapar. Kendi başınıza çalışmaktan ve problem çözmekten keyif alırsınız.\n\n**Deneyime açıklık** puanınızın yüksek olması, bu disiplinli ve içedönük yapıya önemli bir esneklik katıyor. Yeni fikirlere, farklı bakış açılarına ve entelektüel meraklara açıksınız. Bu, rutinlere sıkışıp kalmanızı engeller ve özellikle girişimcilik gibi belirsizlik ve yenilik gerektiren alanlarda size avantaj sağlar. Analitik düşünme ve hızlı öğrenme yetenekleriniz bu özelliğinizden beslenir. Özetle profiliniz, bir hedefe kilitlendiğinde onu metodik bir şekilde inşa edebilen, ancak bunu yaparken yaratıcılığını ve stratejik düşünme yeteneğini de kullanabilen bir "mimar" veya "stratejist" arketipine benziyor.\n\n## Güçlü Yönleriniz\n\n*   **Sarsılmaz Sorumluluk ve Disiplin:** Sorumluluk puanınızın %100 olması, bunun sadece bir özellik değil, bir yaşam biçimi olduğunu gösteriyor. Size bir görev verildiğinde, en iyi şekilde tamamlanacağından emin olunabilir. Bu, iş hayatında güvenilirlik ve başarı için en temel yapı taşıdır. Kendi işinizi kurma hedefinizde, bu özellik en büyük sermayeniz olacaktır.\n\n*   **Analitik ve Stratejik Düşünme:** Kendi belirttiğiniz "analitik düşünme" gücü, deneyime açıklık özelliğinizle birleşiyor. Karmaşık sorunları bileşenlerine ayırabilir, verileri değerlendirebilir ve mantıksal sonuçlara varabilirsiniz. Bu, duygusal tepkilerle değil, kanıta dayalı kararlar almanızı sağlar.\n\n*   **Bağımsız Çalışma ve Odaklanma Yeteneği:** İçedönük yapınız, dikkatinizin dağıldığı ortamlarda performansınızın düşmesine neden olabilir, ancak size derinlemesine odaklanma ve karmaşık projeler üzerinde saatlerce tek başınıza çalışma yeteneği kazandırır. Bu, özellikle bir iş kurmanın ilk aşamalarındaki yoğun ve bireysel çaba gerektiren dönemler için kritik bir avantajdır.\n\n*   **Hızlı Öğrenme ve Zihinsel Esneklik:** Yeni fikirlere açık olmanız, "hızlı öğrenme" yeteneğinizin temelini oluşturur. Değişen pazar koşullarına, yeni teknolojilere veya beklenmedik zorluklara adapte olma kapasiteniz yüksektir. Statik düşünmezsiniz; aksine, daha iyi bir yol bulduğunuzda mevcut planınızı revize etmekten çekinmezsiniz.\n\n## Kör Noktalar ve Riskler\n\n*   **Tükenmişlik ve İş-Yaşam Dengesizliği Riski:** En büyük gücünüz olan yüksek sorumluluk, aynı zamanda en büyük riskinizi oluşturur. Mükemmeliyetçiliğe ve aşırı çalışmaya olan eğiliminiz, "iş-yaşam dengesi ve stres yönetimi" sorununu doğrudan besler. "Yeterli" olanı kabul etmekte zorlanabilir, dinlenme ve sosyal hayatı işin gerisine atabilirsiniz. Bu, uzun vadede hem fiziksel hem de zihinsel sağlığınızı ciddi şekilde tehdit eden bir tükenmişlik sendromuna yol açabilir.\n\n*   **Sosyal İzolasyon ve Ağ Oluşturma Zorlukları:** İçedönük yapınız, özellikle iş kurma sürecinde kritik olan ağ oluşturma (networking), pazarlama ve satış gibi dışadönüklük gerektiren görevlerde sizi zorlayabilir. Enerjinizi sosyal etkileşimlerden ziyade yalnız çalışarak topladığınız için, gerekli bağlantıları kurmaktan kaçınma veya bu tür etkinlikleri aşırı yorucu bulma eğiliminde olabilirsiniz. Bu, işinizin büyümesini yavaşlatabilir.\n\n*   **Aşırı Analiz (Analysis Paralysis):** Analitik düşünme gücünüz, bazen bir zayıflığa dönüşebilir. Karar vermeden önce tüm verileri toplama ve her olasılığı değerlendirme arzunuz, sizi eyleme geçmekten alıkoyabilir. Özellikle girişimcilikte hızlı karar almanın gerektiği anlarda, bu "analiz felci" durumu değerli fırsatları kaçırmanıza neden olabilir.\n\n*   **Yardım İstemede Güçlük:** Sorumluluk duygunuz ve bağımsız çalışma eğiliminiz, başkalarından yardım istemeyi veya görevleri delege etmeyi zorlaştırabilir. Her şeyi kendiniz kontrol etme ve yapma isteği, iş yükünüzü sürdürülemez bir seviyeye çıkarabilir ve ekibinizin veya ortaklarınızın potansiyelinden tam olarak yararlanmanızı engelleyebilir.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişkilerinizde muhtemelen derinlik ve anlam arayan birisiniz. Yüzeysel sohbetler veya büyük, gürültülü sosyal gruplar size çekici gelmez. Bunun yerine, birkaç yakın dostunuzla entelektüel veya anlamlı konular üzerine konuşmayı tercih edersiniz. Güvenilir ve sadık bir dost olmanız muhtemeldir; söz verdiğinizde tutarsınız ve sevdiklerinize karşı sorumluluklarınızı ciddiye alırsınız.\n\nAncak içedönük yapınız, yeni insanlarla tanışırken ilk adımı atmakta veya duygularınızı anında ifade etmekte zorlanmanıza neden olabilir. Dışarıdan mesafeli veya soğuk görünebilirsiniz, oysa bu sadece sizin düşüncelerinizi ve gözlemlerinizi işlemeniz için zamana ihtiyaç duymanızdan kaynaklanır. Partneriniz veya yakın arkadaşlarınız, sizinle iletişim kurmak için sabırlı olmalı ve size kişisel alan tanımalıdır.\n\nPotansiyel bir çatışma noktası, aşırı çalışma eğiliminizdir. Sevdiklerinize yeterli zaman ve enerji ayıramadığınızda, ilişkilerinizde ihmal edilmişlik hissi yaratabilirsiniz. İş-yaşam dengesi kurma mücadeleniz, sadece sizin kişisel sağlığınız için değil, aynı zamanda ilişkilerinizin sağlığı için de kritiktir.\n\n## Kariyer ve Çalışma Tarzı\n\nKariyer yolunuz, bağımsızlık, uzmanlık ve anlamlı bir sonuç üretme üzerine kuruludur. Analitik, planlama gerektiren ve somut sonuçlar doğuran rollerde parlarsınız. Mühendislik, yazılım geliştirme, finansal analiz, strateji danışmanlığı veya kendi işinizi kurmak gibi alanlar sizin için doğal bir uyum gösterir.\n\n**Çalışma Ortamı:** Açık ofisler gibi sürekli kesintiye uğradığınız, gürültülü ortamlar verimliliğinizi düşürür. Odaklanabileceğiniz, kendi başınıza kalabileceğiniz veya küçük, görev odaklı ekiplerle çalışabileceğiniz yapıları tercih edersiniz. Yönetici olarak, muhtemelen adil, mantıklı ve beklentileri net olan bir lider olursunuz. Ancak ekibinizin sosyal ve duygusal ihtiyaçlarını gözden kaçırma riskiniz vardır.\n\n**Karar Verme:** Kararlarınız veri odaklı ve mantıksaldır. İçgüdüsel veya duygusal kararlardan kaçınırsınız. Bu, finansal ve stratejik konularda büyük bir güçtür. Ancak, insan faktörünün veya pazarın irrasyonel dinamiklerinin önemli olduğu durumlarda, bu katı mantıksal yaklaşımınız kör noktalar yaratabilir.\n\n**Girişimcilik Hedefi:** "Kendi işimi kurmak" hedefiniz, kişilik yapınızla hem uyumlu hem de çelişkilidir. Uyumlu yönü, disiplininiz, sorumluluk duygunuz ve bağımsız çalışma yeteneğinizdir. Bir iş planı hazırlama, ürünü geliştirme ve operasyonları yönetme konusunda mükemmel olabilirsiniz. Çelişkili yönü ise, satış, pazarlama, yatırımcı sunumları ve ekip yönetimi gibi yoğun insan etkileşimi gerektiren alanlardır. Başarılı olmak için ya bu alanlarda kendinizi bilinçli olarak geliştirmeniz ya da bu yönlerinizi tamamlayacak dışadönük bir ortak bulmanız gerekecektir.\n\n## Duygusal Desenler ve Stres\n\nStresle başa çıkma yönteminiz muhtemelen içsel ve bilişseldir. Sorunları kendi başınıza çözmeye, durumu analiz etmeye ve mantıklı bir çıkış yolu bulmaya çalışırsınız. "İş-yaşam dengesi ve stres yönetimi" en büyük zorluğunuz olarak belirttiğinize göre, mevcut stratejileriniz yetersiz kalıyor.\n\nYüksek sorumluluk duygunuz, başarısızlık veya hata yapma durumlarında kendinizi sert bir şekilde eleştirmenize neden olabilir. Stres, sizde muhtemelen anksiyete, endişe ve zihinsel yorgunluk olarak ortaya çıkar. Duygularınızı dışa vurmak yerine içinize atma eğiliminiz olabilir. Bu, zamanla birikerek daha büyük patlamalara veya kronik strese yol açabilir.\n\nHobileriniz olan **kitap okuma, yüzme ve doğa yürüyüşü**, içedönük yapınız için mükemmel deşarj mekanizmalarıdır. Bu aktiviteler size zihinsel olarak dinlenmeniz ve enerjinizi yeniden toplamanız için gereken yalnızlığı ve sakinliği sağlar. Stres yönetimi için bu aktivitelere bilinçli olarak zaman ayırmanız hayati önem taşımaktadır.\n\n## Yaşam Desenleri ve Muhtemel Tuzaklar\n\nSizin gibi bir profil, genellikle hayatının erken dönemlerinde akademik veya profesyonel başarıya ulaşır. Disiplininiz ve zekanız sizi ileri taşır. Ancak 20'li yaşların sonu ve 30'lu yaşlar, kariyer başarısının tek başına yeterli olmadığı, sosyal bağların, kişisel tatminin ve sağlığın da önemli olduğunun fark edildiği bir dönemdir.\n\n**Muhtemel Tuzak:** En büyük tuzak, "başarı tuzağı"dır. Hedeflerinize ulaştıkça (örneğin, finansal özgürlük), bu başarıların sizi beklediğiniz kadar mutlu etmediğini fark edebilirsiniz. Çünkü bu süreçte sosyal ilişkilerinizi, sağlığınızı ve anlık keyifleri feda etmiş olabilirsiniz. En mutlu anınızın bir hedefe ulaştığınız "üniversiteden mezun olduğum gün" olması, mutluluğu bir varış noktası olarak gördüğünüzü gösteriyor. Bu, sürekli bir sonraki hedefe koşarken şimdiki anı kaçırma riskini beraberinde getirir.\n\n**Fırsat:** En büyük fırsatınız, disiplininizi ve stratejik zekanızı sadece işinize değil, hayatınızın tamamına uygulamaktır. İş-yaşam dengesini bir görev, sağlığınızı bir proje, ilişkilerinizi ise bilinçli yatırım gerektiren bir alan olarak görebilirsiniz. Planlama yeteneğinizi kullanarak dinlenme, sosyalleşme ve hobiler için takviminizde "müzakere edilemez" zaman dilimleri yaratabilirsiniz.\n\n## Eyleme Geçirilebilir İleriye Dönük Yol Haritası\n\n1.  **"Yeterince İyi" Prensibini Benimseyin:** Mükemmeliyetçiliğinizin sizi tüketmesine izin vermeyin. Her görevde %100'ü hedeflemek yerine, Pareto Prensibini (%80 sonuç %20 çabadan gelir) uygulayın. Hangi görevlerin %100 çaba gerektirdiğini, hangilerinin %80 ile "yeterince iyi" olacağını bilinçli olarak belirleyin. Bu, enerjinizi korumanıza yardımcı olacaktır.\n\n2.  **Takviminize "Hiçbir Şey Yapmama" Zamanı Ekleyin:** Tıpkı önemli bir iş toplantısı gibi, dinlenme ve toparlanma zamanlarınızı da takviminize birer randevu olarak işleyin. Bu zaman dilimlerinde işle ilgili hiçbir şey düşünmemeye veya yapmamaya kendinizi zorlayın. Doğa yürüyüşü veya yüzme gibi hobileriniz bu zamanlar için mükemmeldir.\n\n3.  **Sınırları Belirleyin ve Savunun:** İş gününüzün ne zaman başlayıp ne zaman bittiğini net bir şekilde tanımlayın. Akşamları ve hafta sonları iş e-postalarını kontrol etmeme kuralı koyun. Başlangıçta bu sizi rahatsız edebilir, ancak uzun vadede tükenmişliği önlemek için bu sınırlar zorunludur.\n\n4.  **Ağ Oluşturmayı Bir Proje Olarak Görün:** Sosyal etkinliklerden kaçınmak yerine, bunu işinizin stratejik bir parçası olarak ele alın. Her ay katılmanız gereken bir veya iki sektör etkinliği belirleyin. Amacınız herkesle sohbet etmek değil, sadece iki veya üç anlamlı bağlantı kurmak olsun. Bu, görevi daha yönetilebilir ve daha az yorucu hale getirecektir.\n\n5.  **Bir "Dışadönük" Müttefik Bulun:** Kendi işinizi kurarken, sizin analitik ve operasyonel gücünüzü tamamlayacak, satış ve pazarlama konusunda doğal yeteneği olan bir ortak veya kilit çalışan bulun. Her şeyi tek başınıza yapmak zorunda değilsiniz. Zayıf yönlerinizi kabul etmek ve bu boşlukları başkalarıyla doldurmak bir güç göstergesidir.\n\n6.  **Stres İçin Fiziksel Bir Çıkış Yolu Geliştirin:** Yüzme ve doğa yürüyüşü harika. Stres anında kullanabileceğiniz daha yoğun bir fiziksel aktivite eklemeyi düşünün (örneğin, tempolu koşu, boks). Fiziksel yorgunluk, zihinsel ruminasyonu (aynı şeyleri tekrar tekrar düşünmeyi) kırmanın en etkili yollarından biridir.\n\n7.  **Duygusal Farkındalık Pratiği Yapın:** Günde 5-10 dakika ayırarak o an ne hissettiğinizi (stresli, yorgun, heyecanlı vb.) yargılamadan sadece isimlendirmeye çalışın. Analitik zihniniz duyguları birer "çözülmesi gereken sorun" olarak görebilir. Oysa bazen duyguların sadece fark edilmeye ve kabul edilmeye ihtiyacı vardır.\n\n8.  **"Başarı" Tanımınızı Genişletin:** Finansal özgürlüğün ötesinde, sizin için başarılı bir hayatın ne anlama geldiğini düşünün. Bu tanıma sağlık, ilişkiler, huzur ve öğrenme gibi unsurları da dahil edin. Bu, tek bir hedefe aşırı odaklanarak hayatın diğer alanlarını ihmal etmenizi önleyecektir.\n\n## Kendi Sözlerinizden: Anılar ve Anlam\n\nKendi ifadeleriniz, test sonuçlarının ortaya koyduğu tabloyu hem doğruluyor hem de ona derinlik katıyor. Bu, sadece soyut bir profil değil, sizin yaşadığınız gerçekliğin bir yansımasıdır.\n\n**Hedefleriniz ve Zorluklarınız:** Hayat amacınızı "**Kendi işimi kurmak ve finansal özgürlüğe ulaşmak**" olarak tanımlıyorsunuz. Bu, yüksek sorumluluk ve bağımsızlık ihtiyacınızın somut bir ifadesidir. En büyük zorluğunuz ise "**İş-yaşam dengesi ve stres yönetimi**". Bu iki ifade, madalyonun iki yüzü gibidir. Sizi hedeflerinize taşıyan aynı yoğun çalışma ahlakı, aynı zamanda sizi tüketen mekanizmadır. Bu, sizin merkezi yaşam geriliminizdir.\n\n**Güçlü Yönleriniz:** Kendinizi "**Analitik düşünme, sorumluluk, hızlı öğrenme**" ile tanımlıyorsunuz. Bu, test sonuçlarıyla birebir örtüşüyor. Kendi gücünüzün farkındasınız ve bu yetenekleri bilinçli olarak kullanıyorsunuz. Bu öz-farkındalık, gelişim için sağlam bir temeldir.\n\n**Mutluluk Anınız:** En mutlu anınız olarak "**Üniversiteden mezun olduğum gün**"ü belirtmeniz çok anlamlı. Bu an, rastgele bir keyif anı veya sosyal bir olay değil; uzun süreli, disiplinli bir çabanın sonucunda ulaşılan bir başarıdır. Bu, sizin için mutluluğun büyük ölçüde **hedefe ulaşma ve görev tamamlama** ile bağlantılı olduğunu gösteriyor. Bu bir güç olabilir, ancak aynı zamanda sizi süreçten keyif almaktan alıkoyan bir tuzak da olabilir. Hayat sadece varış noktalarından ibaret değildir; yolculuğun kendisi de önemlidir.\n\nBu ifadelerden çıkan üç temel içgörü şunlardır:\n1.  **Başarı Odaklı Motivasyon:** Sizi harekete geçiren temel güç, somut hedeflere ulaşmaktır. Bu sizi inanılmaz derecede etkili kılar.\n2.  **Sürdürülebilirlik Krizi:** Mevcut çalışma tarzınız ve stresle başa çıkma yöntemleriniz sürdürülebilir değil. Bir değişiklik yapılmazsa, tükenmişlik kaçınılmaz bir sonuç gibi görünüyor.\n3.  **İçsel Referans Noktası:** Değer ve mutluluk ölçütleriniz büyük ölçüde içsel standartlarınıza ve hedeflerinize ulaşmanıza bağlı. Dışsal onay veya sosyal popülerlik sizin için ikincil planda kalıyor.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, psikolojide kabul görmüş çeşitli kişilik modellerine dayanmaktadır. **Beş Faktör Kişilik Modeli (Big Five/OCEAN)**, kişiliğin beş temel boyutunu (Deneyime Açıklık, Sorumluluk, Dışadönüklük, Uyumluluk, Duygusal Denge) ölçen, bilimsel olarak en geçerli ve güvenilir model olarak kabul edilir. Sorumluluk puanınızın yüksekliği, akademik ve profesyonel başarı, daha iyi sağlık alışkanlıkları ve uzun ömür gibi olumlu yaşam sonuçlarıyla güçlü bir şekilde ilişkilidir. Düşük dışadönüklük puanınız ise, daha az risk alma eğilimi ve daha derin ama daha az sayıda sosyal ilişki gibi örüntülerle tutarlıdır.\n\n**MBTI (Myers-Briggs Tipi Göstergesi)**, tam bir profil çıkaracak kadar verimiz olmasa da, karar verme ve bilgi işleme tercihlerine odaklanır. Düşük dışadönüklük puanınıza dayanarak yaptığımız İçedönüklük (I) çıkarımı, enerjinizi nasıl yönlendirdiğinizi anlamamıza yardımcı olur. MBTI, bir tanı aracı olmaktan çok, kişisel farkındalık ve ekip dinamiklerini anlama konusunda bir çerçeve sunar.\n\nBu modellerin hiçbiri geleceği tahmin edemez veya sizi bir kutuya hapsetmez. Aksine, doğal eğilimlerinizi, potansiyel güçlü yönlerinizi ve dikkat etmeniz gereken risk alanlarını gösteren birer harita gibidirler. Davranışlarınız, bu temel eğilimler ile içinde bulunduğunuz durumun, hedeflerinizin ve bilinçli seçimlerinizin bir etkileşimidir. Bu raporun amacı, size bu haritayı sunarak, yolunuzu daha bilinçli bir şekilde çizmenize yardımcı olmaktır.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilendirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-20 23:03:02.252039+03	2025-08-20 23:04:20.022982+03	{"language": "tr", "language_ok": true}	\N	\N	\N	\N	2025-08-29 20:45:13.649121
dbb4114f-6b88-4bfb-832c-45f03788c830	2a1881bf-51c8-4726-ad0e-4206633e351d	self	completed	{"S0_AGE": 28, "S0_GENDER": "Erkek", "S0_LIFE_GOAL": "Kendi işimi kurmak", "S0_HAPPY_MEMORY": "Mezuniyet günü", "S0_TOP_STRENGTHS": "Analitik düşünme", "S0_TOP_CHALLENGES": "Stres yönetimi"}	{"S1_BIG5_001": 4, "S1_BIG5_002": 5, "S1_BIG5_003": 3, "S1_BIG5_004": 2, "S1_BIG5_005": 4, "S1_BIG5_006": 5, "S1_BIG5_007": 3, "S1_BIG5_008": 4, "S1_BIG5_009": 5, "S1_BIG5_010": 3, "S1_DISC_001": "A", "S1_DISC_002": "B", "S1_DISC_003": "A", "S1_DISC_004": "B", "S1_MBTI_001": 2, "S1_MBTI_002": 4, "S1_MBTI_003": 1, "S1_MBTI_004": 3}	Hazır mısın? Başlayalım..\n\nGerektiğinde sivri dilli olabilirim. Dünyayı okuma biçimim tavizsiz bir şekilde doğrudandır. Amacım seni daha güçlü ve mutlu kılmak; bu yüzden bazen seni sert bir şekilde eleştireceğim—seni küçümsemek için asla, seni gerçekliğe demirlemek için her zaman.\n\n| Özellik / Boyut | Puan |\n|----------------------------------|--------------|\n| **MBTI Tipi** | ENTP |\n| MBTI Dışadönüklük (E) | 65% |\n| MBTI İçedönüklük (I) | 35% |\n| MBTI Duyusal (S) | 35% |\n| MBTI Sezgisel (N) | 65% |\n| MBTI Düşünen (T) | 80% |\n| MBTI Hisseden (F) | 20% |\n| MBTI Yargılayan (J) | 50% |\n| MBTI Algılayan (P) | 50% |\n| **Big Five - Deneyime Açıklık (O)** | 63% |\n| **Big Five - Sorumluluk (C)** | 38% |\n| **Big Five - Dışadönüklük (E)** | 38% |\n| **Big Five - Uyumluluk (A)** | 75% |\n| **Big Five - Nevrotiklik (N)** | 13% |\n| **DISC - Dominantlık (D)** | 25% |\n| **DISC - Etkileyicilik (I)** | 25% |\n| **DISC - Durağanlık (S)** | 25% |\n| **DISC - Kuralcılık (C)** | 25% |\n| Bağlanma - Kaygı | Yetersiz veri |\n| Bağlanma - Kaçınma | Yetersiz veri |\n| Çatışma Stili (Birincil) | Yetersiz veri |\n| Duygu Düzenleme - Yeniden Değerlendirme| Yetersiz veri |\n| Duygu Düzenleme - Bastırma | Yetersiz veri |\n| Empati - Duygusal İlgi | Yetersiz veri |\n| Empati - Perspektif Alma | Yetersiz veri |\n\n## Temel Kişiliğin\n\nKişilik profilin, ender rastlanan ve güçlü bir kombinasyon sergiliyor: **analitik bir akıl ile işbirlikçi bir ruhu** bir araya getiriyorsun. Özünde, karmaşık sistemleri anlamaya, olasılıkları keşfetmeye ve fikirleri entelektüel düzeyde tartışmaya yönelik doymak bilmez bir arzuyla hareket eden bir **ENTP (Tartışmacı)** arketipisin. Ancak bu basit bir etiket değil; verilerindeki çelişkiler, seni daha karmaşık ve ilgi çekici kılıyor.\n\nEn belirgin çelişki, dışadönüklük seviyende yatıyor. MBTI testin, sosyal etkileşimden ve fikir alışverişinden enerji aldığını gösterirken (Dışadönüklük %65), Big Five sonuçların daha seçici ve içedönük davranışlara (Dışadönüklük %38) işaret ediyor. Bu, klasik bir "parti canavarı" olmadığın anlamına gelir. Sen bir **ambivert** ya da daha doğrusu **sosyal olarak seçici bir dışadönüksün**. Enerjini, yüzeysel sohbetlerin yapıldığı kalabalık ortamlarda harcamak yerine, zekice tartışmalar yapabileceğin küçük ve güvendiğin bir çevreyle etkileşime girmeyi tercih ediyorsun.\n\nİkinci ve daha önemli çelişki, mantık ve uyum arasındaki dengedir. Çok güçlü bir Düşünme (T) eğilimin (%80) var; bu da kararlarını objektif verilere ve mantıksal tutarlılığa dayandırdığını gösteriyor. Genellikle bu özellik, daha düşük bir uyumlulukla ilişkilendirilir. Ancak senin Uyumluluk (A) puanın oldukça yüksek (%75). Bu, seni **ilkeli ama soğuk olmayan, analitik ama insanları kırmayan** biri yapıyor. Bir problemi, insanları yabancılaştırmadan, salt mantıkla parçalarına ayırabilirsin. Amacın bir tartışmayı kazanmaktan ziyade, en mantıklı ve herkes için en adil çözümü bulmaktır.\n\nAncak en büyük zorluğun, parlak zekan ile eylemlerin arasındaki boşlukta yatıyor. Düşük Sorumluluk (C) puanın (%38), esnek ve anlık hareket etmeye yönelik Algılayan (P) eğiliminle birleştiğinde, hayatının en büyük engelini oluşturuyor: **başlama konusunda harikasın, bitirme konusunda zayıfsın.** Bu durum, özellikle "kendi işini kurma" hedefin için kritik bir tehdittir. DISC profilinin dengeli yapısı (%25 her alanda), duruma göre davranışlarını ayarlayabilen bir bukalemun olduğunu gösteriyor. Bu adaptasyon yeteneği bir güç olsa da, aynı zamanda net bir itici güç veya kararlı bir duruş eksikliğine de işaret edebilir.\n\n## Güçlü Yönlerin\n\n*   **Analitik ve Stratejik Zeka:** Yüksek Düşünme ve Sezgisellik puanların, soyut kavramları anlama, kalıpları görme ve karmaşık stratejiler geliştirme konusunda sana doğal bir yetenek veriyor. Kendi belirttiğin "analitik düşünme" gücün, verilerle de doğrulanıyor. Bu, özellikle iş kurma hedefinde vizyonu belirlemek için en büyük sermayen.\n\n*   **İşbirlikçi Mantık:** Yüksek Düşünme ve yüksek Uyumluluk gibi nadir bir kombinasyona sahipsin. Bu, seni hem rasyonel hem de diplomatik kılar. İnsanları zorlamak yerine mantıkla ikna edersin. Ekip içinde hem en akıllıca çözümü bulabilir hem de bu süreçte uyumu koruyabilirsin.\n\n*   **Duygusal Denge:** Nevrotiklik puanının (%13) olağanüstü derecede düşük olması, temelden sakin, dayanıklı ve strese karşı dirençli bir yapıya sahip olduğunu gösteriyor. Baskı altında soğukkanlılığını korursun ve küçük aksiliklerin moralini bozmasına izin vermezsin. Bu, bir girişimcinin sahip olabileceği en değerli özelliklerden biridir.\n\n*   **Durumsal Uyum Yeteneği:** Dengeli DISC profilin, farklı durumlarda farklı şapkalar takabildiğini gösteriyor. Gerektiğinde doğrudan ve kararlı (Dominant), gerektiğinde ikna edici ve sosyal (Etkileyici), gerektiğinde destekleyici ve sabırlı (Durağan) veya dikkatli ve kuralcı (Kuralcı) olabilirsin. Bu esneklik, seni çok yönlü bir problem çözücü yapar.\n\n## Kör Noktalar ve Riskler\n\n*   **Kronik Erteleme ve Düzensizlik:** Bu, Aşil topuğun. Düşük Sorumluluk (%38) puanın, girişimcilik hedefinin önündeki en büyük engeldir. Fikirler harika olabilir, ancak planlama, takip ve uygulama olmadan hiçbir değeri yoktur. Bu zayıflık, teslim tarihlerini kaçırmana, önemli detayları gözden kaçırmana ve en nihayetinde projelerin başarısız olmasına yol açabilir.\n\n*   **"Parlak Nesne" Sendromu:** Yüksek Deneyime Açıklık ve Sezgisellik, düşük Sorumluluk ile birleştiğinde, sürekli olarak yeni ve daha heyecan verici bir fikrin peşinden gitme eğilimi yaratır. Bir projeyi tamamlamadan diğerine atlarsın. Bu, enerjini dağıtır ve somut bir başarı inşa etmeni engeller.\n\n*   **Stresin Kaynağını Yanlış Anlama:** En büyük zorluğunun "stres yönetimi" olduğunu belirtmişsin. Bu, aşırı düşük Nevrotiklik puanınla tam bir çelişki içindedir. Bu durum, stresinin kaynağının duygusal olmadığını, **davranışsal** olduğunu gösteriyor. Sen, içsel bir kaygıdan dolayı stres yaşamıyorsun; düzensizliğinin ve erteleme alışkanlığının yarattığı **kaosun sonuçlarından** dolayı strese giriyorsun. Son teslim tarihlerinin baskısı, kaçırılan fırsatlar ve plansızlıktan kaynaklanan krizler seni strese sokuyor. Sorun hislerinde değil, sistemlerinde.\n\n*   **Etkisiz Kalan Bir İtici Güç:** Dengeli DISC profilin adaptasyon yeteneği sunsa da, kritik anlarda net bir liderlik veya uzmanlık tarzı sergilemeni engelleyebilir. Girişimcilik, bazen acımasızca Dominant olmayı, bazen de titizlikle Kuralcı olmayı gerektirir. Her şey olmaya çalışmak, hiçbir şeyde uzmanlaşamama riskini taşır.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişkilerde, yüksek Uyumluluk puanın seni sıcak, düşünceli ve işbirlikçi bir partner yapar. Entelektüel bağ kurmaya büyük önem verirsin; senin için ideal bir partner, fikirlerini tartışabileceğin, zihinsel olarak seni zorlayan biridir. Ambivert yapın nedeniyle, büyük partiler veya kalabalık sosyal etkinlikler yerine, birkaç yakın dostunla derin sohbetler etmeyi tercih edersin.\n\nAncak, en büyük çatışma potansiyeli yine düşük Sorumluluk özelliğinden kaynaklanır. Verdiğin sözleri unutabilir, planları son anda değiştirebilir veya günlük sorumlulukları aksatabilirsin. Bu durum, partnerin için yorucu ve istikrarsız bir dinamik yaratabilir. Bir sorunla karşılaştığında, duygusal destek sunmak yerine mantıksal bir "çözüm" bulmaya çalışma eğilimin (yüksek Düşünme), iyi niyetli olsa bile partnerin tarafından duygusal olarak mesafeli algılanabilir.\n\n## Kariyer ve Çalışma Tarzı\n\nSenin için ideal olan, yaratıcı problem çözmeyi, stratejik düşünmeyi ve özerkliği ödüllendiren rollerdir. Strateji danışmanlığı, Ar-Ge, sistem tasarımı veya bir girişimin vizyoner kurucusu olmak gibi pozisyonlar sana mükemmel uyar. Fikir üretme ve büyük resmi görme yeteneğin bu alanlarda parlar. Buna karşılık, detay odaklı, tekrarlayan ve katı kurallara bağlı idari işler seni boğar ve performansını düşürür.\n\n"Kendi işimi kurma" hedefin, güçlü yönlerinle (Sezgisellik, Düşünme) mükemmel bir şekilde örtüşüyor, ancak zayıf yönün (Sorumluluk) nedeniyle devasa bir risk taşıyor. Sen, işin **beyni ve vizyoneri** olabilirsin. Ancak bu vizyonu gerçeğe dönüştürecek, operasyonları yönetecek, finansal tabloları takip edecek ve süreçleri uygulayacak **son derece sorumlu bir ortağa veya operasyon direktörüne (COO) mutlak surette ihtiyacın var.** Bu, senin için bir lüks değil, bir zorunluluktur. Başarın, bu eksiğini nasıl telafi ettiğine bağlı olacaktır.\n\n## Duygusal Desenler ve Stres\n\nTekrar vurgulamak gerekirse, senin stresin içsel bir fırtınadan değil, dışsal bir kaostan kaynaklanıyor. Varsayılan durumun sakinliktir (düşük Nevrotiklik). Seni strese sokan tetikleyiciler, kendi eylemsizliğinin veya plansızlığının biriktirdiği dış baskılardır: haftalardır görmezden geldiğin bir projenin teslim tarihinin yaklaşması gibi.\n\nBu tür bir stresle başa çıkma yöntemin muhtemelen daha fazla düşünmektir. Sorunu analiz etmeye, mantıksal bir çıkış yolu bulmaya çalışırsın. Bu, teknik sorunlar için işe yarar, ancak disiplin eksikliğinden kaynaklanan sorunlar için tamamen işlevsizdir. Dağınık bir odayı analiz ederek temizleyemezsin; sadece temizlemen gerekir.\n\n## Yaşam Desenleri ve Muhtemel Tuzaklar\n\nEğer mevcut gidişatını değiştirmezsen, "parlak ama potansiyelini gerçekleştirememiş" arketipine dönüşme riskin var. Hayatın, %80'i tamamlanmış sayısız ilginç proje ile dolu olabilir. Kariyerinde, derin bir ustalık veya dönüm noktası niteliğinde bir başarı elde etmek yerine, ilginç işler veya girişimler arasında geçiş yapabilirsin. Bu geniş bir deneyim birikimi sağlar, ancak somut ve kalıcı bir miras bırakmanı engeller.\n\nHayatındaki temel değiş tokuş şudur: **güvenilirliği esneklikle takas ediyorsun.** Hedeflerine ulaşmak için, doğana aykırı gelse bile bu dengeyi bilinçli olarak güvenilirlik lehine kaydırmak zorundasın. Bu, özgürlüğünden vazgeçmek değil, yaratıcılığının meyve vereceği bir yapı inşa etmektir.\n\n## Eyleme Geçirilebilir İleriye Dönük Yol Haritası\n\n1.  **Sorumlu Bir Ortak Bul:** İş hedefin için, Excel tablolarını, proje planlarını ve son teslim tarihlerini seven bir kurucu ortak bul. Bu, atabileceğin en önemli adımdır. Kişisel hayatında da, seni yapılandırma konusunda destekleyen bir partnere değer ver.\n\n2.  **Yapıyı Dışsallaştır:** İrade gücüne güvenme. İrade, tükenen bir kaynaktır. Bunun yerine, sistemlere güven. Takvimler, proje yönetimi araçları (Trello, Asana gibi), alarmlar ve hatırlatıcıları acımasızca kullan. Senin için başkaları tarafından belirlenen teslim tarihleri yarat.\n\n3.  **"İki Dakika Kuralı"nı Uygula:** Eğer bir görev iki dakikadan az sürüyorsa, hemen yap. Bu, "daha sonra yaparım" ataletini kırar ve küçük ama önemli işlerin birikmesini engeller (örneğin, bir e-postayı yanıtlamak).\n\n4.  **"Stres" Tanımını Değiştir:** "Stres yönetimi" sorununu bir "sistem yönetimi" sorunu olarak yeniden çerçevele. Stresli hissettiğinde, "Neden böyle hissediyorum?" diye sorma. Bunun yerine, "Hangi sistem çöktü?" veya "Hangi planı uygulamadım?" diye sor.\n\n5.  **Özgürlüğünü Planla:** Algılayan (P) doğan, spontanlığa ihtiyaç duyar. Öyleyse, onu planla. Takvimine "serbest düşünme zamanı" veya "yapılandırılmamış günler" ekle. Böylece esneklik ihtiyacın, tüm haftanı rayından çıkarmaz.\n\n6.  **Mantık+Uyum Gücünü Kullan:** Müzakerelerde veya anlaşmazlıklarda, hem mantıklı hem de nazik olma yeteneğine bilinçli olarak yaslan. Argümanlarını nesnel verilere ve ortak ilkelere dayandırırken, karşı tarafın bakış açısını anladığını ve saygı duyduğunu göster.\n\n7.  **Tek Bir Şeyi Bitir:** Önemli bir kişisel veya profesyonel proje seç ve yeni bir şeye başlamadan önce onu %100 tamamlamaya odaklan. Bu, "bitirme kasını" geliştirir ve bunu yapabileceğini kendine kanıtlar.\n\n8.  **Disiplini Yeniden Anlamlandır:** Disiplini bir ceza olarak değil, yaratıcılığının gelişmesini sağlayan bir çerçeve olarak gör. Bir sarmaşığı destekleyen çit onun için bir kafes değildir; güneşe doğru büyümesini sağlayan yapıdır. Senin sistemlerin, senin çitin olacak.\n\n## Kendi Sözlerinle: Anılar ve Anlam\n\nAnalizlerimizi, senin kendi ifadelerinle birleştirelim. Bunlar, soyut verilerin ötesinde, senin yaşayan deneyimindir.\n\n*   **Hedefin: "Kendi işimi kurmak."** Bu, ENTP profilinin özerklik, meydan okuma ve fikir üretme arzusunun nihai bir ifadesidir. Bu hedef, kim olduğunun bir yansımasıdır ve peşinden gitmeye değer. Ancak yukarıda belirtilen riskler, bu hedefe giden yoldaki mayınlardır.\n\n*   **Güçlü Yönün: "Analitik düşünme."** Kendini doğru tanıyorsun. Bu, %80'lik Düşünme puanınla tamamen uyumlu. Bu senin kimliğinin bir parçası ve en güvendiğin aracın.\n\n*   **Zorluğun: "Stres yönetimi."** Bu, en aydınlatıcı ifaden. Düşük Nevrotiklik puanınla olan çelişkisi, stresinin kaynağının duygusal değil, davranışsal ve durumsal olduğunu kanıtlıyor. Yaşadığın stres gerçek, ancak kaynağı yanlış teşhis edilmiş.\n\n*   **Mutlu Anın: "Mezuniyet günü."** Bu anı, bir **başarı ve tamamlanma** anısıdır. Uzun, yapılandırılmış bir projenin başarılı bir şekilde sonunu işaret eder. Bu, senin için güçlü bir duygusal çıpadır. Erteleme ile mücadele ettiğinde, o gün hissettiğin gururu ve rahatlamayı hatırlamak, güçlü bir motivasyon kaynağı olabilir. Bu anı, doğana karşı gelip bir şeyi sonuna kadar götürdüğünde nelerin mümkün olduğunu temsil ediyor.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, psikolojide kabul görmüş çeşitli modellere dayanmaktadır. **Big Five (Beş Faktör) modeli**, kişiliğin temel ve istikrarlı özelliklerini tanımlar. Sorumluluk (Conscientiousness) gibi özelliklerin akademik ve profesyonel başarıyı, Nevrotikliğin (Neuroticism) ise strese karşı duyarlılığı öngörmede ne kadar güçlü olduğu kanıtlanmıştır. Senin düşük Sorumluluk ve düşük Nevrotiklik profilin, hem büyük bir potansiyeli hem de çok özel bir zorluğu bir arada barındıran nadir bir durumdur.\n\n**MBTI (Myers-Briggs Tip Göstergesi)**, bir kişilik testi olmaktan çok, bilgiyi nasıl işlediğine ve kararları nasıl verdiğine dair bir tercih modelidir. Senin ENTP tipin, olasılıkları keşfetme (Sezgisellik) ve bunları mantıksal çerçevelerle (Düşünme) analiz etme tercihini vurgular. Raporumuzdaki en derinlemesine analizler, MBTI ve Big Five verileri arasındaki çelişkilerden (Dışadönüklük ve Uyumluluk gibi) doğmuştur, çünkü bu nüanslar seni standart bir kalıbın dışına çıkarır.\n\n**DISC modeli**, özellikle iş ve ekip ortamlarındaki gözlemlenebilir davranış tarzını açıklar. Senin dengeli profilin, davranışsal esnekliğini gösterir. Bu modellerin hiçbiri tek başına tam bir resim sunmaz. Güçleri, bir araya geldiklerinde ortaya çıkar: Big Five **ne olduğunu** (temel özelliklerin), MBTI **nasıl düşündüğünü** (bilişsel tercihlerin) ve DISC **nasıl davrandığını** (durumsal eylemlerin) açıklar. Bu rapor, bu katmanları birleştirerek, seni daha bütünsel bir şekilde anlamayı hedefler ve önerilerini bu entegre anlayış üzerine kurar.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilendirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-20 23:08:29.830147+03	2025-08-20 23:10:18.607552+03	{"language": "tr", "language_ok": true}	\N	\N	\N	\N	2025-08-29 20:45:13.649121
2baa8322-7c04-42f5-b0c2-696e03b7ae4b	f55dfb24-6a6e-495d-86c7-897a73ffcb88	self	completed	{"S0_AGE": 30, "S0_GENDER": "Kadın", "S0_LIFE_GOAL": "Test amaç"}	{"S1_BIG5_001": 5, "S1_BIG5_002": 4}	Hazır mısınız? Başlayalım..\n\nGerektiğinde sivri dilli olabilirim. Dünyayı okuma biçimim özür dilemeksizin doğrudandır. Amacım sizi daha güçlü ve mutlu kılmaktır; bu yüzden zaman zaman sizi sert bir şekilde eleştireceğim - asla sizi küçümsemek için değil, her zaman sizi gerçeğe demirlemek için.\n\n| Özellik / Boyut | Puan |\n|-----------------------------------|---------------------------------|\n| **MBTI Tipi** | Hesaplama için yetersiz veri |\n| MBTI Dışadönüklük (E) | Hesaplama için yetersiz veri |\n| MBTI İçedönüklük (I) | Hesaplama için yetersiz veri |\n| MBTI Duyumsama (S) | Hesaplama için yetersiz veri |\n| MBTI Sezgi (N) | Hesaplama için yetersiz veri |\n| MBTI Düşünme (T) | Hesaplama için yetersiz veri |\n| MBTI Hissetme (F) | Hesaplama için yetersiz veri |\n| MBTI Yargılama (J) | Hesaplama için yetersiz veri |\n| MBTI Algılama (P) | Hesaplama için yetersiz veri |\n| **Big Five - Deneyime Açıklık (O)** | Hesaplama için yetersiz veri |\n| **Big Five - Sorumluluk (C)** | Hesaplama için yetersiz veri |\n| **Big Five - Dışadönüklük (E)** | Hesaplama için yetersiz veri |\n| **Big Five - Uyumluluk (A)** | Hesaplama için yetersiz veri |\n| **Big Five - Duygusal Dengesizlik (N)** | Hesaplama için yetersiz veri |\n| **DISC - Hakimiyet (D)** | Hesaplama için yetersiz veri |\n| **DISC - Etki (I)** | Hesaplama için yetersiz veri |\n| **DISC - Kararlılık (S)** | Hesaplama için yetersiz veri |\n| **DISC - Uyum (C)** | Hesaplama için yetersiz veri |\n| Bağlanma - Kaygı | Hesaplama için yetersiz veri |\n| Bağlanma - Kaçınma | Hesaplama için yetersiz veri |\n| Çatışma Stili (Birincil) | Hesaplama için yetersiz veri |\n| Duygu Düzenleme - Yeniden Değerlendirme| Hesaplama için yetersiz veri |\n| Duygu Düzenleme - Bastırma | Hesaplama için yetersiz veri |\n| Empati - Duygusal İlgi | Hesaplama için yetersiz veri |\n| Empati - Perspektif Alma | Hesaplama için yetersiz veri |\n\n## Temel Kişiliğiniz\n\nKişilik profilinizi kapsamlı bir şekilde analiz etmek için gerekli olan MBTI, Big Five ve DISC değerlendirmelerine verdiğiniz yanıtlar mevcut değil veya yetersiz. Bu temel veriler olmadan, davranışsal eğilimleriniz, bilişsel tercihleriniz ve temel mizaç özellikleriniz hakkında anlamlı bir portre çizmek mümkün değildir. Bu analiz, kişiliğinizin farklı durumlarda nasıl tezahür ettiğini anlamak için bu üç modelin entegrasyonuna dayanır; ancak bu veri eksikliği nedeniyle şu anda size özel bir analiz sunamıyorum.\n\n## Güçlü Yönler\n\nGüçlü yönlerinizi belirlemek, kişilik testlerinden elde edilen puanların yanı sıra kendi bildirdiğiniz yetkinliklerin bir analizini gerektirir. Psikometrik verileriniz olmadan, hangi özelliklerin sizin için doğal bir avantaj sağladığını objektif olarak değerlendiremem. Örneğin, yüksek Sorumluluk (Conscientiousness) puanı genellikle güvenilirlik ve organizasyon becerisine işaret ederken, yüksek Etki (Influence) puanı ikna kabiliyetini gösterebilir. Bu veriler olmadan, güçlü yönleriniz hakkında yapılacak herhangi bir yorum spekülasyondan öteye geçemez.\n\n## Kör Noktalar ve Riskler\n\nBenzer şekilde, potansiyel kör noktalarınız ve risk alanlarınız da kişilik verilerinizle yakından ilişkilidir. Örneğin, yüksek Duygusal Dengesizlik (Neuroticism) strese karşı artan bir hassasiyete işaret edebilirken, düşük Uyumluluk (Agreeableness) kişilerarası çatışma riskini artırabilir. Bu değerlendirmeler yapılmadan, hangi davranış kalıplarının sizin için zorluk yaratabileceğini veya sizi istenmeyen sonuçlara sürükleyebileceğini belirlemek imkansızdır. Size özel, eyleme geçirilebilir geri bildirim sağlamak için bu temel ölçümlere ihtiyacım var.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişki kurma biçiminiz, çatışmaları nasıl yönettiğiniz ve sosyal ortamlardaki davranışlarınız, bağlanma stiliniz, empati düzeyiniz ve temel kişilik özelliklerinizden büyük ölçüde etkilenir. Bağlanma, çatışma stili ve empati testlerine verdiğiniz yanıtlar olmadan, sosyal dinamikleriniz hakkında derinlemesine bir analiz yapamam. Bu veriler, yakın ilişkilerde, arkadaşlıklarda ve ekip çalışmalarında karşılaşabileceğiniz olası zorlukları ve bu zorluklarla başa çıkma stratejilerini anlamak için kritik öneme sahiptir.\n\n## Kariyer ve Çalışma Tarzı\n\nDISC profili, iş yerindeki davranışsal tarzınızı anlamak için temel bir araçtır. Hakimiyet, Etki, Kararlılık ve Uyum boyutlarındaki eğilimleriniz, liderlik potansiyelinizi, ekip içindeki rolünüzü, karar alma süreçlerinizi ve hangi çalışma ortamlarında en verimli olacağınızı gösterir. Bu veri olmadan, kariyerinize uygun roller, potansiyel mesleki zorluklar veya performansınızı artıracak koşullar hakkında size özel ve somut tavsiyeler sunmak mümkün değildir.\n\n## Duygusal Desenler ve Stres\n\nDuygusal tepkilerinizi ve stresle başa çıkma mekanizmalarınızı anlamak, Duygusal Dengesizlik (Neuroticism) puanınıza ve duygu düzenleme stratejilerinize (yeniden değerlendirme, bastırma) bağlıdır. Bu veriler, sizi neyin tetiklediğini, stres altında varsayılan tepkilerinizin ne olduğunu ve duygusal tırmanışları nasıl önleyebileceğinizi anlamamıza yardımcı olur. Bu bilgiler olmadan, duygusal sağlığınızı yönetmenize yönelik kişiselleştirilmiş bir rehberlik sunamam.\n\n## Yaşam Desenleri ve Olası Tuzaklar\n\nKişilik profilleri, bireylerin yaşamları boyunca karşılaşabilecekleri belirli fırsatları ve tuzakları öngörmemize yardımcı olabilir. Örneğin, yüksek Deneyime Açıklık ve düşük Sorumluluk sahibi bir kişi, birçok projeye başlayıp hiçbirini bitirmeme tuzağına düşebilir. Sizin profiliniz hakkında veri olmadan, yaşam yolunuzda karşınıza çıkabilecek olası desenler, avantajlar veya zorluklar hakkında gerçekçi öngörülerde bulunamam.\n\n## Eyleme Geçirilebilir İleriye Dönük Yol\n\nMevcut durumda, size özel ve derinlemesine tavsiyeler sunmak için yeterli veriye sahip değilim. Bu nedenle, en önemli ve tek eylem planı, bu analizin temelini oluşturan psikolojik değerlendirmeleri tamamlamanızdır.\n\n*   **Değerlendirmeleri Tamamlayın:** Size doğru ve faydalı bir analiz sunabilmem için ilk adım, kişilik, davranış ve ilişki tarzlarınızı ölçen testleri eksiksiz bir şekilde tamamlamaktır. Bu, size sunacağım içgörülerin isabetliliği için temel bir gerekliliktir.\n*   **Dürüst ve İçten Yanıtlar Verin:** Testleri yanıtlarken, ideal benliğinizi değil, mevcut durumunuzu en dürüst şekilde yansıtan cevapları seçin. Analizin doğruluğu, verdiğiniz yanıtların samimiyetine bağlıdır.\n*   **Kişisel Hedeflerinizi Netleştirin:** Değerlendirmeleri tamamlarken, bu süreçten ne elde etmek istediğinizi düşünün. İlişkilerinizi mi geliştirmek istiyorsunuz, kariyerinizde mi netlik arıyorsunuz, yoksa kendinizi daha iyi anlamak mı istiyorsunuz? Hedefleriniz ne kadar net olursa, analiz o kadar odaklı olur.\n*   **Açık Uçlu Sorulara Zaman Ayırın:** En mutlu anılarınız, en zorlu deneyimleriniz ve hedefleriniz gibi açık uçlu sorular, sayısal verilerin ötesinde bir derinlik katmaktadır. Bu bölümleri düşünerek ve ayrıntılı bir şekilde doldurmak, analizin kalitesini önemli ölçüde artıracaktır.\n\nBu adımları tamamladıktan sonra, size özel, derinlemesine ve eyleme geçirilebilir bir analiz sunmak mümkün olacaktır.\n\n## Kendi Sözlerinizle: Anılar ve Anlam\n\nAnaliz için gerekli olan anılarınızı, hedeflerinizi veya zorluklarınızı paylaşmadınız. Ancak, "yaşam amacı" sorusuna verdiğiniz yanıt, mevcut durumunuz hakkında önemli bir ipucu veriyor.\n\nYaşam amacınız olarak **"Test amaç"** ifadesini kullandınız.\n\nBu yanıt, şu anda bu sürece derinlemesine bir kendini keşif yolculuğu olarak değil, daha çok sistemin nasıl çalıştığını görmek için bir deneme olarak yaklaştığınızı gösteriyor. Bu, yargılanacak bir durum değildir; aksine, temkinli ve analitik bir yaklaşımın işareti olabilir. Bir sisteme tam olarak yatırım yapmadan önce onu test etme, sınırlarını anlama ve güvenilirliğini ölçme isteği, gerçekçi ve metodik bir zihniyeti yansıtır. Bu raporun şu anki sınırlılığı da bu başlangıç yaklaşımınızın doğal bir sonucudur. Daha derin bir analize hazır olduğunuzda, değerlendirmeleri tamamlama kararını verecek olan yine sizsiniz.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, psikolojide kabul görmüş ve yaygın olarak kullanılan çeşitli teorik çerçevelere dayanmaktadır. Size özel bir analiz sunamasam da bu çerçevelerin ne işe yaradığını açıklamak önemlidir.\n\n**Beş Faktör Kişilik Modeli (Big Five/OCEAN)**, kişiliğin temel yapısını beş ana boyutta (Deneyime Açıklık, Sorumluluk, Dışadönüklük, Uyumluluk, Duygusal Dengesizlik) ele alan, bilimsel olarak en sağlam ve geçerli modeldir. Bu özellikler, iş başarısından ilişki memnuniyetine, ruh sağlığından yaşam süresine kadar birçok önemli yaşam sonucuyla tutarlı bir şekilde ilişkilendirilmiştir. Örneğin, yüksek Sorumluluk, akademik ve mesleki başarı için güçlü bir yordayıcıdır.\n\n**MBTI (Myers-Briggs Tipi Göstergesi)**, insanların dünyayı nasıl algıladığı ve kararlarını nasıl verdiği konusundaki psikolojik tercihleri ölçer. Dışadönüklük/İçedönüklük, Duyumsama/Sezgi, Düşünme/Hissetme ve Yargılama/Algılama olmak üzere dört temel ikilem üzerine kuruludur. MBTI, bir tanı aracı olmaktan çok, bireylerin bilişsel tarzlarını ve iletişim tercihlerini anlamalarına yardımcı olan bir çerçeve sunar.\n\n**DISC modeli** ise özellikle profesyonel ortamlardaki gözlemlenebilir davranışlara odaklanır. Hakimiyet (Dominance), Etki (Influence), Kararlılık (Steadiness) ve Uyum (Compliance) olmak üzere dört temel davranışsal eğilimi ölçer. Bu model, bir kişinin görevlere ve diğer insanlara nasıl yaklaştığını anlamak, ekip dinamiklerini iyileştirmek ve liderlik tarzını belirlemek için oldukça pratiktir.\n\nBu üç model bir araya geldiğinde, kişiliğinizin farklı katmanlarını (temel mizaç, bilişsel tercihler ve durumsal davranışlar) bütüncül bir şekilde görmemizi sağlar. Değerlendirmeleri tamamladığınızda, bu kanıta dayalı çerçeveler kullanılarak sizin için anlamlı ve eyleme geçirilebilir bir profil oluşturulacaktır.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilendirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-20 23:10:50.296525+03	2025-08-20 23:11:36.875448+03	{"language": "tr", "language_ok": true}	\N	\N	\N	\N	2025-08-29 20:45:13.649121
93f3e145-44f1-4235-af55-67263bfe823b	d3fde6ba-27df-4240-a304-322dccf7ad06	self	completed	\N	\N	Hazır mısınız? Başlayalım..\n\nBu analiz, kendinizi daha net görmeniz için tasarlanmış bir aynadır. Amacımız sizi rahatlatmak değil, sizi güçlendirmektir. Burada okuyacaklarınız, potansiyelinizi engelleyen ve sizi hedeflerinizden alıkoyan kalıplarla yüzleşmeniz için bir davettir. Stratejik ve gerçekçi bir bakış açısıyla, mevcut durumunuzu, bunun altında yatan dinamikleri ve ulaşabileceğiniz geleceği masaya yatıracağız. Bu süreç rahatsız edici olabilir, çünkü gerçek büyüme konfor alanının dışında başlar.\n\n| Özellik / Boyut | Puan |\n|----------------------------------|----------------------------------------------------|\n| **MBTI Tipi** | INFP |\n| MBTI Dışadönüklük (E) | 20% |\n| MBTI İçedönüklük (I) | 80% |\n| MBTI Duyusal (S) | 25% |\n| MBTI Sezgisel (N) | 75% |\n| MBTI Düşünen (T) | 40% |\n| MBTI Hisseden (F) | 60% |\n| MBTI Yargılayan (J) | 50% |\n| MBTI Algılayan (P) | 50% |\n| **Big Five - Deneyime Açıklık (O)** | 50% |\n| **Big Five - Sorumluluk (C)** | 50% |\n| **Big Five - Dışadönüklük (E)** | 40% |\n| **Big Five - Uyumluluk (A)** | 80% |\n| **Big Five - Duygusal Dengesizlik (N)** | 60% |\n| **DISC - Baskınlık (D)** | Düşük |\n| **DISC - Etkileyicilik (I)** | Yüksek |\n| **DISC - Sadakat (S)** | Çok Yüksek |\n| **DISC - Uygunluk (C)** | Çok Düşük |\n| Bağlanma - Kaygı | 25% |\n| Bağlanma - Kaçınma | 100% |\n| Çatışma Stili (Birincil) | Kaçınmacı |\n| Duygu Düzenleme - Yeniden Değerlendirme | 25% |\n| Duygu Düzenleme - Bastırma | 58% |\n| Empati - Duygusal İlgi | 100% |\n| Empati - Perspektif Alma | 83% |\n| Anlam ve Amaç Puanı | 67% |\n| Gelecek Zaman Perspektifi Puanı | 81% |\n| Baskın Bilişsel Çarpıtmalar | Ya Hep Ya Hiç Düşüncesi, Zihin Okuma |\n| Mevcut Somatik Durum | Savaş/Kaç (Mobilizasyon) |\n\n## Temel Kişiliğiniz\n\nAnaliziniz, merkezinde derin bir çelişki barındıran bir tablo çiziyor. Bir yanda INFP profilinizin ve yüksek Uyumluluk puanınızın işaret ettiği, son derece empatik, uyum arayan, insan odaklı bir doğa var. DISC profilinizdeki çok yüksek Sadakat (S) ve yüksek Etkileyicilik (I) de bunu doğruluyor; siz, ilişkilerde barışı korumayı, insanları desteklemeyi ve pozitif bir atmosfer yaratmayı derinden önemseyen birisiniz. Ancak bu tablonun altında, neredeyse mutlak bir değer alan (%100) Kaçınmacı Bağlanma stili yatıyor. Bu, kişiliğinizin en temel ve en kritik dinamiğidir.\n\nBu durumu en iyi özetleyen arketip **"Kafesteki Diplomat"**tır. Diplomat yönünüz, insanlarla bağ kurma, onların duygularını anlama (Empati puanlarınız tavan yapmış durumda) ve çatışmadan kaçınma arzunuzu temsil ediyor. Ancak "kafes", sizin tarafınızdan, başkaları tarafından kontrol edilme ve benliğinizi kaybetme korkusuyla inşa edilmiş. Kendi ifadenizle, *"Beni kısıtlayacak birinin (eşimin) yanımda olması kendim olmamı engelliyor."* Bu cümle, sizin temel varoluşsal mücadelenizi özetliyor: **yakınlığa duyulan özlem ile yutulma korkusu arasındaki savaş.**\n\nDüşük Baskınlık (D) puanınız, bu dinamiğin davranışsal sonucudur. "Yanlış anlaşılmak ve lafımı kimseye dinletememek" olarak tanımladığınız en büyük zorluk, şanssızlık veya başkalarının hatası değil; sizin çatışmadan kaçınmak için kendi sesinizi sistematik olarak kısmınızın doğrudan bir sonucudur. Barışı korumak adına kendi ihtiyaçlarınızı ve düşüncelerinizi feda ediyorsunuz, sonra da duyulmadığınız için hayal kırıklığına uğruyorsunuz.\n\nDüşük Uygunluk (C) ve kararsız Yargılayan/Algılayan (J/P) eğiliminiz, "İstikrarlı olabilmeyi isterdim" haykırışınızın temelini oluşturur. Fikirler ve olasılıklar dünyasında yaşamayı seviyorsunuz (yüksek Sezgisellik), ancak bu fikirleri eyleme dökecek yapı ve disiplini oluşturmakta zorlanıyorsunuz. Bu durum, Trendyol'da satış yapma gibi girişimci hedefleriniz için ciddi bir engel teşkil eder.\n\nKısacası, dışarıdan sıcak, cana yakın ve destekleyici görünen birinin içinde, özerkliğini korumak için duvarlar ören, kontrol edilmekten ölesiye korkan ve bu yüzden de gerçek potansiyelini bir kafesin içinde tutan biri var.\n\n## Güçlü Yönleriniz\n\n*   **Olağanüstü Empati ve İnsan Odaklılık:** %100 Duygusal İlgi ve %83 Perspektif Alma puanlarınızla, insanların duygusal dünyalarına nüfuz etme konusunda ender bir yeteneğe sahipsiniz. Bu sizi harika bir dost, sırdaş ve destekleyici bir takım arkadaşı yapar. İnsanlar sizin yanınızda kendilerini anlaşılmış hissederler, çünkü siz onları gerçekten "görürsünüz".\n\n*   **Umut Dolu Gelecek Perspektifi:** %81'lik Gelecek Zaman Perspektifi puanınız, en önemli varlıklarınızdan biridir. Mevcut zorluklara rağmen, geleceğin daha iyi olabileceğine dair güçlü bir inancınız var. Bu, sizi ayakta tutan, yeni hedefler (otomatik araba almak gibi) belirlemenizi sağlayan içsel bir motordur. Bu umut, doğru stratejilerle birleştiğinde, sizi ileriye taşıyacak en büyük yakıttır.\n\n*   **Barış ve Uyum Yaratma Yeteneği:** Yüksek Sadakat (S) ve Uyumluluk (A) puanlarınız, sizi doğal bir arabulucu ve denge unsuru yapar. Gergin ortamları yumuşatma, insanları bir araya getirme ve destekleyici bir atmosfer yaratma konusunda yeteneklisiniz. Bu, doğru kullanıldığında, hem kişisel hem de profesyonel ilişkilerde paha biçilmez bir güçtür.\n\n*   **İlham Verme ve Pozitif Etki:** Yüksek Etkileyicilik (I) skorunuz, neşeli ve pozitif doğanızla insanları motive etme potansiyeliniz olduğunu gösterir. Kendi ifadenizle, "Güler yüzlü olmam insanların hoşuna gidiyor pozitif olmam." Bu, sosyal ağlar kurma ve insanları bir fikrin etrafında toplama konusunda size bir avantaj sağlar.\n\n## Kör Noktalar ve Riskler\n\nBu bölüm acımasız olacak, çünkü olmak zorunda. Kör noktalarınız, sadece küçük kusurlar değil, hayatınızdaki en büyük hayal kırıklıklarının ve pişmanlıkların kaynağıdır. Onları net bir şekilde görmeden, aynı döngüleri tekrar yaşamaya mahkumsunuz.\n\n*   **Çatışmadan Kaçınma Bir Barış Stratejisi Değil, Kendine İhanettir:**\n    *   **Kalıp:** Bir anlaşmazlık çıktığında, özellikle kişisel hayatınızda, barışı korumak adına geri çekiliyor, susuyor ve konudan kaçıyorsunuz (Birincil Çatışma Stiliniz: Kaçınmacı).\n    *   **Bedeli:** Kendi sesinizi, ihtiyaçlarınızı ve sınırlarınızı sistematik olarak yok sayıyorsunuz. Bu, zamanla birikerek içeride büyük bir öfke ve kırgınlığa dönüşüyor. "Yanlış anlaşılmak" hissi, aslında sizin kendinizi ifade etmeyi reddetmenizin bir yansımasıdır. Bu pasiflik, başkalarının sizi yönetmesine ve sınırlarınızı ihlal etmesine zemin hazırlar.\n    *   **Altında Yatan Güdü:** Reddedilme ve eleştirilme korkusu. Sizin için uyumun bozulması, kişisel bir başarısızlık gibi hissettiriyor. Bu yüzden kısa vadeli huzursuzluktan kaçmak için uzun vadeli mutluluğunuzu feda ediyorsunuz.\n    *   **Bilinçdışı Kazanç:** Bu davranışın size gizli bir faydası var: Sizi, kendi fikirlerinizi savunmanın ve bunun sonuçlarıyla yüzleşmenin getireceği sorumluluktan koruyor. Susarak, "Eğer konuşsaydım haklı olurdum ama huzur için sustum" yanılsamasını sürdürebilirsiniz. Bu, başarısızlık riskini almaktan kaçınmanın pasif bir yoludur.\n\n*   **Aşırı Kaçınmacı Bağlanma: Yakınlık Eşittir Esaret Denklemi:**\n    *   **Kalıp:** %100 Kaçınmacı Bağlanma skorunuz, bir istatistik değil, bir alarmdır. Yakınlığı ve bağımlılığı bir tehdit olarak algılıyorsunuz. Birisi size yaklaştığında, boğuluyor ve kontrolü kaybediyor gibi hissediyorsunuz. Bu yüzden bilinçsizce mesafe yaratırsınız.\n    *   **Bedeli:** Gerçek, derin ve karşılıklı bir bağ kurmanızı engeller. İlişkilerinizde sürekli bir "gel-git" dinamiği yaratırsınız: Yalnızken yakınlık istersiniz, yakınlık kurulduğunda ise kaçacak yer ararsınız. Eşinizi "sizi kısıtlayan" olarak görmeniz, bu içsel dinamiğin dışa yansımasıdır. Sorun eşiniz değil, sizin yakınlıkla kurduğunuz "tehlike" ilişkisidir.\n    *   **Altında Yatan Güdü:** Benliğini, özerkliğini kaybetme korkusu. Geçmiş deneyimleriniz size "bir başkasına ait olmanın, kendini kaybetmek" olduğunu öğretmiş olabilir.\n\n*   **Duygusal Bastırma: Bedeninizdeki Saatli Bomba:**\n    *   **Kalıp:** Duygularınızı yönetmek için yeniden değerlendirme (%25) yerine bastırmayı (%58) tercih ediyorsunuz. Yani, olumsuz bir duygu geldiğinde onu anlamaya ve dönüştürmeye çalışmak yerine, onu "yokmuş gibi" davranarak içinize atıyorsunuz.\n    *   **Bedeli:** Bastırılan duygular yok olmaz; şekil değiştirir. Sizin durumunuzda, kronik bir "Savaş/Kaç" moduna, omuzlarınızda, sırtınızda ve midenizde biriken fiziksel ağrılara dönüşüyor. Düşük enerji seviyeniz (3/10) ve kötü uyku kaliteniz (4/10), bedeninizin bu bastırılmış duygusal enerjiyi taşımaktan yorulduğunun kanıtıdır.\n    *   **Altında Yatan Güdü:** Olumsuz duyguların "kötü" veya "tehlikeli" olduğuna dair derin bir inanç. Öfke, hayal kırıklığı gibi duyguları ifade etmenin ilişkileri yok edeceğinden korkuyorsunuz.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişki dünyanız, bahsettiğimiz temel çelişkinin sahnesidir. Yüksek empati ve uyumluluğunuzla insanları kendinize çekersiniz. Sıcak, anlayışlı ve iyi bir dinleyici olarak tanınırsınız. Ancak bu, madalyonun sadece bir yüzüdür.\n\nİlişki derinleştikçe, Kaçınmacı Bağlanma stiliniz devreye girer. Partneriniz daha fazla yakınlık ve bağlılık aradığında, siz kendinizi kapana kısılmış hissetmeye başlarsınız. Bu, "beni kısıtlıyor" düşüncesini tetikler. Tepkiniz, doğrudan bir iletişim kurmak yerine pasif-agresif davranışlar veya duygusal geri çekilme olur. Partneriniz bu mesafeyi hisseder ve daha fazla ilgi göstermeye çalışır, bu da sizi daha da boğar ve kaçma isteğinizi artırır. Bu, "takipçi-mesafeli" adı verilen klasik bir ilişki tuzağıdır ve sonu genellikle her iki taraf için de büyük bir hayal kırıklığıdır.\n\nÇatışma anlarında kaçınmacı stiliniz, sorunların çözülmeden halının altına süpürülmesine neden olur. Küçük anlaşmazlıklar birikir ve zamanla büyük bir kırgınlık dağına dönüşür. Sizin için "barışı korumak", aslında sorunların kangren olmasına izin vermektir.\n\n## Kariyer ve Çalışma Tarzı\n\nMevcut durumunuz ("bir giriş elemanıyım ayrıca trendyol'dan satış yapmaya başladım") ve kişilik profiliniz arasında ciddi bir uyumsuzluk riski var.\n\nDISC profiliniz (Yüksek S/I, Düşük D/C), sizi mükemmel bir müşteri ilişkileri veya destek personeli yapar. İnsanlara yardım etmeyi, onlarla iyi ilişkiler kurmayı ve sadakat oluşturmayı seversiniz. Ancak bir girişimci veya işletme sahibi olmak, tam olarak zayıf olduğunuz alanları gerektirir: Baskınlık (D) ve Uygunluk (C).\n\nBir işletmeyi yönetmek; net kararlar almayı, risk üstlenmeyi, pazarlık yapmayı, standartları belirlemeyi ve bazen sevimsiz olmayı göze almayı gerektirir (Düşük D'nizin tam zıttı). Ayrıca, envanter takibi, finansal planlama, sipariş yönetimi gibi detaylı, sistematik ve kural bazlı işler gerektirir (Düşük C'nizin kabusu).\n\nBu yolda devam ederseniz, müşterilerinizle harika dostluklar kurabilir ama kâr etmeyen, büyümeyen ve sürekli operasyonel krizler yaşayan bir işletmeye sahip olabilirsiniz. "İstikrarlı olamama" ve "tembellik" olarak adlandırdığınız şeyler, aslında bu görevlerin doğanıza ne kadar aykırı olduğunun bir işaretidir. Başarılı olmak için bu alanları bilinçli olarak geliştirmeniz veya bu görevleri delege etmeniz şarttır.\n\n## Duygusal Desenler ve Stres\n\nStres tepkiniz son derece nettir. Sizin için birincil tetikleyiciler **eleştirilmek, kontrol edilmek veya görmezden gelinmektir.** Bu durumlar yaşandığında, ilk tepkiniz duyguyu bastırmak ve durumu görmezden gelmektir (Kaçınma).\n\nAncak bedeniniz bu oyuna kanmaz. Zihniniz "sorun yok" derken, sinir sisteminiz "Savaş/Kaç" moduna geçer. Omuzlarınız gerilir, sırtınız ağrır, mideniz kasılır. Bu, bastırdığınız öfke veya hayal kırıklığının fiziksel çığlığıdır. Bu kronik alarm durumu, enerji seviyenizi tüketir, uykunuzu sabote eder ve sizi sürekli yorgun ve gergin bırakır. "Orta Düzey Stres" (7/10) olarak belirttiğiniz seviye, sizin için artık "normal" hale gelmiş bir kriz durumudur. Bedeniniz, zihninizin ifade etmeyi reddettiği savaşı veriyor.\n\n## Yaşam Desenleri ve Muhtemel Tuzaklar\n\nBu profille, hayatınızda tekrarlayan bir desen görmeniz muhtemeldir: **Potansiyelin Eşiğinde Takılıp Kalma.** Yüksek gelecek umudunuzla (FTP) yeni heveslere ve projelere (Trendyol işi gibi) başlarsınız. Başlangıçtaki sosyal ve heyecan verici kısımları seversiniz (Yüksek I). Ancak proje, disiplin, yapı ve potansiyel çatışma (örneğin, bir tedarikçiyle pazarlık yapmak) gerektirdiğinde, ilginizi kaybeder ve geri çekilirsiniz (Düşük C ve D). Sonuç olarak, birçok "başlanmış ama bitirilmemiş" proje ve "keşke" ile dolu bir geçmiş biriktirme riskiyle karşı karşıyasınız.\n\nEn büyük tuzağınız, mutluluğunuzun ve başarınızın önündeki engelin dışsal olduğuna inanmaktır: "Eşim izin verse...", "İnsanlar beni dinlese...", "Şartlar farklı olsa...". Gerçekte ise en büyük engel, özerklik korkunuzla inşa ettiğiniz içsel kafestir. Kendi kendinize koyduğunuz bu sınırlar, başkalarının size koyabileceği tüm sınırlardan daha kısıtlayıcıdır.\n\n## Yol Ayrımınız: İki Muhtemel Gelecek\n\nBugünkü analize dayanarak, önümüzdeki 5 yıl için iki farklı senaryo öngörebiliriz. Hangi yolda yürüyeceğiniz tamamen sizin seçiminizdir.\n\n**Yol 1: 'Aynen Devam' Geleceği**\n\nBu yolda, temel dinamiklerinizi değiştirmek için hiçbir şey yapmazsınız. Çatışmadan kaçınmaya, duygularınızı bastırmaya ve yakınlıktan korkmaya devam edersiniz. Trendyol işiniz, ara sıra ilgilendiğiniz bir hobi olarak kalır, çünkü büyümek için gereken zorlu kararları almaktan kaçınırsınız. İlişkinizde, eşinize karşı birikmiş kırgınlık sessizce büyür. Kendinizi giderek daha fazla "kurban" gibi hisseder, "pasif ve korkak" olduğunuza dair inancınızı pekiştirirsiniz. Kronik stres, fiziksel sağlığınızı daha fazla etkilemeye başlar; sırt ve mide ağrıları hayatınızın bir parçası olur. 5 yıl sonra, bugün hayalini kurduğunuz "kendi ayakları üzerinde duran kadın" olmaktan daha da uzakta olduğunuzu fark edersiniz. Otomatik araba, bir özgürlük sembolü değil, ulaşılamamış bir hayal olarak kalır.\n\n**Yol 2: 'Potansiyel' Geleceği**\n\nBu yolda, bugünü bir dönüm noktası olarak kabul edersiniz. Kör noktalarınızla yüzleşme cesaretini gösterirsiniz. Küçük adımlarla, sağlıklı sınırlar koymayı öğrenirsiniz. Eşinize ihtiyaçlarınızı suçlayıcı bir dille değil, "Benim ...'ya ihtiyacım var" gibi net ifadelerle anlatmaya başlarsınız. Bu başlangıçta korkutucu olur ama her denemede özgüveniniz artar. Trendyol işiniz için bir sistem kurarsınız; her gün sadece 1 saat ayırarak disiplin kasınızı geliştirirsiniz. Düşük Baskınlık (D) özelliğinizi, "agresif olmak" yerine "kararlı olmak" olarak yeniden çerçevelersiniz. Duygularınızı bastırmak yerine, onları birer sinyal olarak görmeyi öğrenirsiniz. 5 yıl sonra, sadece kâr eden bir işe değil, aynı zamanda kendine saygısı olan bir kadına dönüşürsünüz. İlişkiniz, karşılıklı saygıya dayalı daha dengeli bir ortaklığa evrilir. Ve o otomatik arabayı aldığınızda, bu sadece bir ulaşım aracı değil, kendi iradenizle inşa ettiğiniz yeni hayatınızın bir zafer anıtı olur.\n\n## Uygulanabilir İlerleme Yolu\n\nDeğişim, büyük ve soyut kararlarla değil, küçük, somut ve tutarlı eylemlerle gerçekleşir. İşte başlangıç için 10 adımlık stratejiniz:\n\n1.  **"Hayır" Kasını Geliştirin:** Bu hafta, size hiçbir faydası olmayan üç küçük ve önemsiz şeye "hayır" deyin. Bir arkadaşınızın anlamsız bir isteği, size uymayan bir plan... Sadece sonuçları görmek için "hayır" deme alıştırması yapın. Dünyanın başınıza yıkılmadığını göreceksiniz.\n\n2.  **"Ben Dili" ile İhtiyaç Bildirimi:** "Sen sürekli beni eleştiriyorsun" yerine, "Bana bu şekilde konuştuğunda kendimi değersiz hissediyorum ve senden daha yapıcı bir dil kullanmanı rica ediyorum" demeyi deneyin. Suçlamayı bırakıp kendi duygunuzun ve ihtiyacınızın sorumluluğunu alın.\n\n3.  **Yapısal Zaman Blokları Oluşturun:** Her gün, takviminize "Trendyol Saati" olarak 30 dakikalık, pazarlık kabul etmez bir blok koyun. O 30 dakika boyunca sadece işle ilgili bir şey yapın. Amaç satış yapmak değil, tutarlılık alışkanlığı kazanmaktır.\n\n4.  **Somatik Boşalma Ritüeli:** Gün sonunda veya stres hissettiğinizde, omuzlarınızdaki ve boynunuzdaki gerilimi fark edin. 5 dakika boyunca omuzlarınızı silkeleyin, başınızı yavaşça çevirin, esneyin. Bedeninizde biriken stresi bilinçli olarak serbest bırakın.\n\n5.  **"Zihin Okuma" Varsayımını Sorgulayın:** Birinin sizi yanlış anladığını veya eleştirdiğini düşündüğünüzde, durun ve kendinize sorun: "Bu kişinin niyetinin bu olduğuna dair %100 kanıtım var mı? Başka hangi olası açıklamalar olabilir?" Varsaymak yerine soru sorun.\n\n6.  **Özerklik Anlarını Belirleyin ve Koruyun:** "Kendim olmak" sizin için ne anlama geliyor? Yazlıkta veya maç izlerken neyi farklı yapıyorsunuz? Bu davranışları (belki de sadece rahatça oturmak veya düşüncelere dalmak) haftalık rutininize bilinçli olarak ekleyin. Bu, "eşimden kaçış" değil, "kendime dönüş" zamanı olmalı.\n\n7.  **Değerlerinizi Önceliklendirin:** Size verilen 10 değerden sadece üçünü seçmek zorunda olsaydınız, hangileri olurdu? Hayatınızı bu ilk üç değere göre mi yaşıyorsunuz? Yaşamıyorsanız, hangi küçük değişiklikleri yapabilirsiniz?\n\n8.  **Duygu Günlüğü Tutun:** Sadece bir hafta boyunca, her gün sonunda sizi en çok zorlayan duyguyu (öfke, hayal kırıklığı, endişe) yazın. Onu bastırmak yerine sadece adını koyun. "Bugün kırgınlık hissettim." Bu, duyguları tanıma ve kabul etme yolunda ilk adımdır.\n\n9.  **Gelecek Perspektifinizi Eyleme Dökün:** O otomatik arabayı bir hedef olarak alın. Fiyatını araştırın. Ayda ne kadar kenara koymanız gerektiğini hesaplayın. Hayali, bir plana dönüştürün. Bu, umudunuzu somut bir stratejiye bağlayacaktır.\n\n10. **Profesyonel Yardım Almayı Düşünün:** Kaçınmacı Bağlanma gibi derin köklü bir kalıbı tek başına kırmak son derece zordur. Bir terapist, bu kalıpların kökenini anlamanıza ve sağlıklı ilişki kurma becerileri geliştirmenize yardımcı olabilir. Bu bir zayıflık değil, stratejik bir güç hamlesidir.\n\n## Kendi Sözlerinizden: Anılar ve Anlam\n\nPaylaştığınız anılar, kişilik profilinizin sadece bir doğrulaması değil, aynı zamanda onun duygusal haritasıdır. Bu anıları neden seçtiğiniz, kim olduğunuz hakkında test sonuçlarından çok daha fazlasını söyler.\n\n*   **Ana Anlatı Temaları:**\n    *   **Özgürlük ve Tutsaklık Çatışması:** Bu, anlatınızın bel kemiğidir. Bir yanda "kendi başına trafiğe çıkmak" gibi mutlak bir özerklik ve başarı anı var. Diğer yanda ise eşinizin varlığıyla "kendin olamama" hissi. Bu, Kaçınmacı Bağlanma stilinizin ve düşük Baskınlık puanınızın gerçek hayattaki tezahürüdür. Özgürlüğü yalnızlıkla, yakınlığı ise boğulmayla eşleştiriyorsunuz.\n    *   **Pasifliğin Getirdiği Pişmanlık (Kirlenme Anlatısı):** "Bu kadar pasif ve korkak olmasaydım. Keşke okusaydim..." cümleniz, potansiyeli olan iyi bir hayatın, eylemsizlik nedeniyle lekelendiği bir "kirlenme anlatısıdır". Bu, sadece bir pişmanlık değil, aynı zamanda kimliğinizin bir parçası haline gelmiş bir hikaye. Bu hikaye, mevcut durumunuzdaki sorumluluğunuzdan kaçmak için bir mazeret görevi görüyor olabilir.\n    *   **Kayıp ve Yeniden Doğuş (Kefaret Anlatısı):** En acı verici anılarınızdan biri olan "Babamın ölümü", en mutlu anılarınızdan biriyle, "yeğenim Ahmet'in doğumu babamın vefatı sonrası ilaç gibi geldi" ifadesiyle dengeleniyor. Bu, klasik bir kefaret anlatısıdır: Kötü bir olay (kayıp), iyi bir olayın (yeni yaşam) ortaya çıkmasına neden olur ve bu da hayata bir anlam ve umut katar. Bu, sizin en zor zamanlarda bile bir anlam ve bağlantı bulma kapasitenizi gösterir ve yüksek empati puanınızla tamamen uyumludur.\n\nBu anılar, mücadelenizin özünü ortaya koyuyor: Bir yanınız, babanızın kaybından sonra bir yeğenle yeniden hayata tutunacak kadar derin bağlar kurmak istiyor. Diğer yanınız ise, bir eşin varlığında bile kendini kaybedeceğinden korkacak kadar özerkliğine düşkün. Mevcut Anlam ve Amaç Puanınızın orta düzeyde (%67) olması şaşırtıcı değil. Hayatınızda hem derin anlam kaynakları (aile, sevgi) hem de anlamı baltalayan derin çatışmalar (özgürlük vs. yakınlık) bir arada bulunuyor. İlerlemenin yolu, bu iki ihtiyacın birbiriyle savaşmak zorunda olmadığını anlamaktan geçiyor: Hem derin bir bağ kurup hem de "kendiniz" olabileceğiniz bir yaşam inşa edebilirsiniz. Ama bu, önce sınırları, iletişimi ve kendine saygıyı öğrenmeyi gerektirir.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, size anlık bir fikir vermek için değil, psikolojik ölçüm araçlarından elde edilen verileri bütüncül bir şekilde yorumlamak için tasarlanmıştır. Vardığımız sonuçlar, birden fazla güvenilir teorik çerçeveye dayanmaktadır.\n\nTemel kişilik yapınız, on yıllardır yaygın olarak kullanılan iki model olan Myers-Briggs Tip Göstergesi (MBTI) ve Beş Faktörlü Kişilik Modeli (Big Five) kullanılarak analiz edilmiştir. MBTI, bilgi işleme ve karar verme tercihlerinizi (INFP) ortaya koyarken, Big Five, temel mizaç özelliklerinizi (yüksek Uyumluluk, orta düzeyde Duygusal Dengesizlik gibi) sayısal olarak ölçmüştür. Davranışsal eğilimleriniz ve çalışma tarzınız, insanların çevreleriyle nasıl etkileşime girdiğini dört temel boyutta (Baskınlık, Etkileyicilik, Sadakat, Uygunluk) inceleyen DISC modeliyle haritalandırılmıştır.\n\nİlişki dinamikleriniz, John Bowlby'nin Bağlanma Teorisi temel alınarak incelenmiştir. Verdiğiniz yanıtlar, erken dönem ilişkilerinizde oluşan ve yetişkinlikteki romantik ilişkilerinizi derinden etkileyen bir bağlanma modelini (Kaçınmacı) işaret etmektedir. Duygu düzenleme, çatışma stilleri ve empati gibi sosyal-duygusal yetkinlikleriniz, bu alanlardaki yerleşik araştırma modellerine dayalı olarak değerlendirilmiştir.\n\nSon olarak, bilişsel alışkanlıklarınız (Bilişsel Çarpıtmalar), yaşama bakış açınız (Gelecek Zaman Perspektifi, Anlam ve Amaç) ve zihin-beden bağlantınız (Somatik Farkındalık) da analize dahil edilerek, sadece kim olduğunuzun değil, aynı zamanda dünyayı nasıl deneyimlediğinizin ve geleceğe nasıl baktığınızın çok katmanlı bir portresi oluşturulmuştur. Kendi sözlerinizle paylaştığınız anılar, bu nicel verileri doğrulamak ve onlara derinlik katmak için kullanılmıştır.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilindirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-25 01:12:29.182674+03	2025-08-25 01:14:32.203787+03	{"language": "tr", "language_ok": true}	{"F1_AGE": "39", "F1_GENDER": "1", "F1_EDUCATION": "1", "F1_OCCUPATION": "Bir giriş elemanıyım ayrıca trendyol'dan satış yapmaya başladım", "F1_FOCUS_AREAS": ["0", "7", "1"], "F1_YEARLY_GOAL": "Otomatik araba almak", "F1_ENERGY_LEVEL": 3, "F1_RELATIONSHIP": "2", "F1_STRESS_LEVEL": 7, "F1_SLEEP_QUALITY": 4, "F1_BIGGEST_CHALLENGE": "Yanlış anlaşılmak ve lafımı kimseye dinletememek.", "F1_LIFE_SATISFACTION": 5, "F1_PHYSICAL_ACTIVITY": "0"}	{"F2_VALUES": ["achievement", "power", "benevolence", "self_direction", "universalism", "stimulation", "security", "conformity", "hedonism", "tradition"], "F2_BIG5_01": 3, "F2_BIG5_02": 2, "F2_BIG5_03": 4, "F2_BIG5_04": 5, "F2_BIG5_05": 5, "F2_BIG5_06": 2, "F2_BIG5_07": 3, "F2_BIG5_08": 2, "F2_BIG5_09": 3, "F2_BIG5_10": 4, "F2_MBTI_01": "0", "F2_MBTI_02": "1", "F2_MBTI_03": "1", "F2_MBTI_04": "0", "F2_MBTI_05": "0", "F2_MBTI_06": "0", "F2_MBTI_07": "1", "F2_MBTI_08": "0", "F2_MBTI_09": "1", "F2_MBTI_10": "0", "F2_MBTI_11": "1", "F2_MBTI_12": "1", "F2_MBTI_13": "0", "F2_MBTI_14": "1", "F2_MBTI_15": "0", "F2_MBTI_16": "0", "F2_MBTI_17": "1", "F2_MBTI_18": "1", "F2_MBTI_19": "1", "F2_MBTI_20": "0"}	{"F3_FTP_01": 3, "F3_FTP_02": 5, "F3_FTP_03": 4, "F3_FTP_04": 5, "F3_DISC_01": {"most": "1", "least": "0"}, "F3_DISC_02": {"most": "1", "least": "0"}, "F3_DISC_03": {"most": "2", "least": "3"}, "F3_DISC_04": {"most": "2", "least": "1"}, "F3_DISC_05": {"most": "2", "least": "1"}, "F3_DISC_06": {"most": "1", "least": "3"}, "F3_DISC_07": {"most": "1", "least": "3"}, "F3_DISC_08": {"most": "0", "least": "1"}, "F3_DISC_09": {"most": "2", "least": "3"}, "F3_DISC_10": {"most": "1", "least": "0"}, "F3_DAILY_01": 7, "F3_DAILY_02": 6, "F3_DAILY_03": 7, "F3_DAILY_04": "Eşimin hiç susmadan sürekli kendini savunmaya çalışması \\nOlumlu olansa çok özlediğim arkadaşımı görmek ", "F3_STORY_01": "Beni kısıtlayacak birinin (eşimin) yanımda olması kendim olmamı engelliyor bu yüzden mesela yazlıkta kendim gibi olabiliyorum. Yada onsuz maç izlerken çünkü eleştirilmeyi sevmem. ", "F3_STORY_02": "Güler yüzlü olmam insanların hoşuna gidiyor pozitif olmam \\nEmpati kurmam ", "F3_STORY_03": "İstikrarlı olabilmeyi isterdim \\nTembelligimden kurtulmak \\nÜşengeç olmayı bırakmak ", "F3_STORY_04": "Kendi başıma trafiğe çıkmak yakın tarihte en çok mutlu eden şey buydu.\\nUzak tarihte kızımı dünyaya getirmem. Ve yeğenim Ahmet'in doğumu babamın vefatı sonrası ilaç gibi geldi ", "F3_STORY_05": "Babamın ölümü \\nDiş ağrısı çekmem\\nDoğum sonrası çektiğim ağrı", "F3_STORY_06": "Bu kadar pasif ve korkak olmasaydım. Keşke okusaydim ve doğru düzgün bir mesleğim olsaydı kendi ayakları üzerinde duran bir kadın olsaydım.", "F3_STORY_07": "İlk maaşımı aldığımda eve kendi paramla alışveriş yapmıştım bu çok iyiydi ", "F3_STORY_08": "Satışlarımız artması para sıkıntısı çekmediğimiz zamanlar. En korktuğum ise kötü bir hastalığa yakalanmak ve kızımın başarısız olması ", "F3_ATTACH_01": 1, "F3_ATTACH_02": 5, "F3_ATTACH_03": 1, "F3_ATTACH_04": 5, "F3_ATTACH_05": 4, "F3_ATTACH_06": 5, "F3_BELIEF_01": 2, "F3_BELIEF_02": 5, "F3_BELIEF_03": 4, "F3_BELIEF_04": 5, "F3_BELIEF_05": 5, "F3_BELIEF_06": 4, "S3_EMPATHY_1": 5, "S3_EMPATHY_2": 5, "S3_EMPATHY_3": 5, "S3_EMPATHY_4": 3, "S3_EMPATHY_5": 5, "S3_EMPATHY_6": 5, "F3_MEANING_01": 5, "F3_MEANING_02": 2, "F3_MEANING_03": 4, "F3_SOMATIC_01": "1", "F3_SOMATIC_02": ["2", "3", "6"], "S3_CONFLICT_1": [4], "S3_CONFLICT_2": [2], "F3_COG_DIST_01": ["0", "2"], "S3_EMOTION_REG_1": 2, "S3_EMOTION_REG_2": 3, "S3_EMOTION_REG_3": 2, "S3_EMOTION_REG_4": 4, "S3_EMOTION_REG_5": 2, "S3_EMOTION_REG_6": 3, "F3_COPING_MECHANISMS": [0, 1, 3], "F3_SABOTAGE_PATTERNS": [0, 1, 5]}	[{"id": "block-0", "content": "Hazır mısınız? Başlayalım..\\n\\nBu analiz, kendinizi daha net görmeniz için tasarlanmış bir aynadır. Amacımız sizi rahatlatmak değil, sizi güçlendirmektir. Burada okuyacaklarınız, potansiyelinizi engelleyen ve sizi hedeflerinizden alıkoyan kalıplarla yüzleşmeniz için bir davettir. Stratejik ve gerçekçi bir bakış açısıyla, mevcut durumunuzu, bunun altında yatan dinamikleri ve ulaşabileceğiniz geleceği masaya yatıracağız. Bu süreç rahatsız edici olabilir, çünkü gerçek büyüme konfor alanının dışında başlar.\\n\\n| Özellik / Boyut | Puan |\\n|----------------------------------|----------------------------------------------------|\\n| **MBTI Tipi** | INFP |\\n| MBTI Dışadönüklük (E) | 20% |\\n| MBTI İçedönüklük (I) | 80% |\\n| MBTI Duyusal (S) | 25% |\\n| MBTI Sezgisel (N) | 75% |\\n| MBTI Düşünen (T) | 40% |\\n| MBTI Hisseden (F) | 60% |\\n| MBTI Yargılayan (J) | 50% |\\n| MBTI Algılayan (P) | 50% |\\n| **Big Five - Deneyime Açıklık (O)** | 50% |\\n| **Big Five - Sorumluluk (C)** | 50% |\\n| **Big Five - Dışadönüklük (E)** | 40% |\\n| **Big Five - Uyumluluk (A)** | 80% |\\n| **Big Five - Duygusal Dengesizlik (N)** | 60% |\\n| **DISC - Baskınlık (D)** | Düşük |\\n| **DISC - Etkileyicilik (I)** | Yüksek |\\n| **DISC - Sadakat (S)** | Çok Yüksek |\\n| **DISC - Uygunluk (C)** | Çok Düşük |\\n| Bağlanma - Kaygı | 25% |\\n| Bağlanma - Kaçınma | 100% |\\n| Çatışma Stili (Birincil) | Kaçınmacı |\\n| Duygu Düzenleme - Yeniden Değerlendirme | 25% |\\n| Duygu Düzenleme - Bastırma | 58% |\\n| Empati - Duygusal İlgi | 100% |\\n| Empati - Perspektif Alma | 83% |\\n| Anlam ve Amaç Puanı | 67% |\\n| Gelecek Zaman Perspektifi Puanı | 81% |\\n| Baskın Bilişsel Çarpıtmalar | Ya Hep Ya Hiç Düşüncesi, Zihin Okuma |\\n| Mevcut Somatik Durum | Savaş/Kaç (Mobilizasyon) |"}, {"id": "block-1", "content": "## Temel Kişiliğiniz\\n\\nAnaliziniz, merkezinde derin bir çelişki barındıran bir tablo çiziyor. Bir yanda INFP profilinizin ve yüksek Uyumluluk puanınızın işaret ettiği, son derece empatik, uyum arayan, insan odaklı bir doğa var. DISC profilinizdeki çok yüksek Sadakat (S) ve yüksek Etkileyicilik (I) de bunu doğruluyor; siz, ilişkilerde barışı korumayı, insanları desteklemeyi ve pozitif bir atmosfer yaratmayı derinden önemseyen birisiniz. Ancak bu tablonun altında, neredeyse mutlak bir değer alan (%100) Kaçınmacı Bağlanma stili yatıyor. Bu, kişiliğinizin en temel ve en kritik dinamiğidir.\\n\\nBu durumu en iyi özetleyen arketip **\\"Kafesteki Diplomat\\"**tır. Diplomat yönünüz, insanlarla bağ kurma, onların duygularını anlama (Empati puanlarınız tavan yapmış durumda) ve çatışmadan kaçınma arzunuzu temsil ediyor. Ancak \\"kafes\\", sizin tarafınızdan, başkaları tarafından kontrol edilme ve benliğinizi kaybetme korkusuyla inşa edilmiş. Kendi ifadenizle, *\\"Beni kısıtlayacak birinin (eşimin) yanımda olması kendim olmamı engelliyor.\\"* Bu cümle, sizin temel varoluşsal mücadelenizi özetliyor: **yakınlığa duyulan özlem ile yutulma korkusu arasındaki savaş.**\\n\\nDüşük Baskınlık (D) puanınız, bu dinamiğin davranışsal sonucudur. \\"Yanlış anlaşılmak ve lafımı kimseye dinletememek\\" olarak tanımladığınız en büyük zorluk, şanssızlık veya başkalarının hatası değil; sizin çatışmadan kaçınmak için kendi sesinizi sistematik olarak kısmınızın doğrudan bir sonucudur. Barışı korumak adına kendi ihtiyaçlarınızı ve düşüncelerinizi feda ediyorsunuz, sonra da duyulmadığınız için hayal kırıklığına uğruyorsunuz.\\n\\nDüşük Uygunluk (C) ve kararsız Yargılayan/Algılayan (J/P) eğiliminiz, \\"İstikrarlı olabilmeyi isterdim\\" haykırışınızın temelini oluşturur. Fikirler ve olasılıklar dünyasında yaşamayı seviyorsunuz (yüksek Sezgisellik), ancak bu fikirleri eyleme dökecek yapı ve disiplini oluşturmakta zorlanıyorsunuz. Bu durum, Trendyol'da satış yapma gibi girişimci hedefleriniz için ciddi bir engel teşkil eder.\\n\\nKısacası, dışarıdan sıcak, cana yakın ve destekleyici görünen birinin içinde, özerkliğini korumak için duvarlar ören, kontrol edilmekten ölesiye korkan ve bu yüzden de gerçek potansiyelini bir kafesin içinde tutan biri var."}, {"id": "block-2", "content": "## Güçlü Yönleriniz\\n\\n*   **Olağanüstü Empati ve İnsan Odaklılık:** %100 Duygusal İlgi ve %83 Perspektif Alma puanlarınızla, insanların duygusal dünyalarına nüfuz etme konusunda ender bir yeteneğe sahipsiniz. Bu sizi harika bir dost, sırdaş ve destekleyici bir takım arkadaşı yapar. İnsanlar sizin yanınızda kendilerini anlaşılmış hissederler, çünkü siz onları gerçekten \\"görürsünüz\\".\\n\\n*   **Umut Dolu Gelecek Perspektifi:** %81'lik Gelecek Zaman Perspektifi puanınız, en önemli varlıklarınızdan biridir. Mevcut zorluklara rağmen, geleceğin daha iyi olabileceğine dair güçlü bir inancınız var. Bu, sizi ayakta tutan, yeni hedefler (otomatik araba almak gibi) belirlemenizi sağlayan içsel bir motordur. Bu umut, doğru stratejilerle birleştiğinde, sizi ileriye taşıyacak en büyük yakıttır.\\n\\n*   **Barış ve Uyum Yaratma Yeteneği:** Yüksek Sadakat (S) ve Uyumluluk (A) puanlarınız, sizi doğal bir arabulucu ve denge unsuru yapar. Gergin ortamları yumuşatma, insanları bir araya getirme ve destekleyici bir atmosfer yaratma konusunda yeteneklisiniz. Bu, doğru kullanıldığında, hem kişisel hem de profesyonel ilişkilerde paha biçilmez bir güçtür.\\n\\n*   **İlham Verme ve Pozitif Etki:** Yüksek Etkileyicilik (I) skorunuz, neşeli ve pozitif doğanızla insanları motive etme potansiyeliniz olduğunu gösterir. Kendi ifadenizle, \\"Güler yüzlü olmam insanların hoşuna gidiyor pozitif olmam.\\" Bu, sosyal ağlar kurma ve insanları bir fikrin etrafında toplama konusunda size bir avantaj sağlar."}, {"id": "block-3", "content": "## Kör Noktalar ve Riskler\\n\\nBu bölüm acımasız olacak, çünkü olmak zorunda. Kör noktalarınız, sadece küçük kusurlar değil, hayatınızdaki en büyük hayal kırıklıklarının ve pişmanlıkların kaynağıdır. Onları net bir şekilde görmeden, aynı döngüleri tekrar yaşamaya mahkumsunuz.\\n\\n*   **Çatışmadan Kaçınma Bir Barış Stratejisi Değil, Kendine İhanettir:**\\n    *   **Kalıp:** Bir anlaşmazlık çıktığında, özellikle kişisel hayatınızda, barışı korumak adına geri çekiliyor, susuyor ve konudan kaçıyorsunuz (Birincil Çatışma Stiliniz: Kaçınmacı).\\n    *   **Bedeli:** Kendi sesinizi, ihtiyaçlarınızı ve sınırlarınızı sistematik olarak yok sayıyorsunuz. Bu, zamanla birikerek içeride büyük bir öfke ve kırgınlığa dönüşüyor. \\"Yanlış anlaşılmak\\" hissi, aslında sizin kendinizi ifade etmeyi reddetmenizin bir yansımasıdır. Bu pasiflik, başkalarının sizi yönetmesine ve sınırlarınızı ihlal etmesine zemin hazırlar.\\n    *   **Altında Yatan Güdü:** Reddedilme ve eleştirilme korkusu. Sizin için uyumun bozulması, kişisel bir başarısızlık gibi hissettiriyor. Bu yüzden kısa vadeli huzursuzluktan kaçmak için uzun vadeli mutluluğunuzu feda ediyorsunuz.\\n    *   **Bilinçdışı Kazanç:** Bu davranışın size gizli bir faydası var: Sizi, kendi fikirlerinizi savunmanın ve bunun sonuçlarıyla yüzleşmenin getireceği sorumluluktan koruyor. Susarak, \\"Eğer konuşsaydım haklı olurdum ama huzur için sustum\\" yanılsamasını sürdürebilirsiniz. Bu, başarısızlık riskini almaktan kaçınmanın pasif bir yoludur.\\n\\n*   **Aşırı Kaçınmacı Bağlanma: Yakınlık Eşittir Esaret Denklemi:**\\n    *   **Kalıp:** %100 Kaçınmacı Bağlanma skorunuz, bir istatistik değil, bir alarmdır. Yakınlığı ve bağımlılığı bir tehdit olarak algılıyorsunuz. Birisi size yaklaştığında, boğuluyor ve kontrolü kaybediyor gibi hissediyorsunuz. Bu yüzden bilinçsizce mesafe yaratırsınız.\\n    *   **Bedeli:** Gerçek, derin ve karşılıklı bir bağ kurmanızı engeller. İlişkilerinizde sürekli bir \\"gel-git\\" dinamiği yaratırsınız: Yalnızken yakınlık istersiniz, yakınlık kurulduğunda ise kaçacak yer ararsınız. Eşinizi \\"sizi kısıtlayan\\" olarak görmeniz, bu içsel dinamiğin dışa yansımasıdır. Sorun eşiniz değil, sizin yakınlıkla kurduğunuz \\"tehlike\\" ilişkisidir.\\n    *   **Altında Yatan Güdü:** Benliğini, özerkliğini kaybetme korkusu. Geçmiş deneyimleriniz size \\"bir başkasına ait olmanın, kendini kaybetmek\\" olduğunu öğretmiş olabilir.\\n\\n*   **Duygusal Bastırma: Bedeninizdeki Saatli Bomba:**\\n    *   **Kalıp:** Duygularınızı yönetmek için yeniden değerlendirme (%25) yerine bastırmayı (%58) tercih ediyorsunuz. Yani, olumsuz bir duygu geldiğinde onu anlamaya ve dönüştürmeye çalışmak yerine, onu \\"yokmuş gibi\\" davranarak içinize atıyorsunuz.\\n    *   **Bedeli:** Bastırılan duygular yok olmaz; şekil değiştirir. Sizin durumunuzda, kronik bir \\"Savaş/Kaç\\" moduna, omuzlarınızda, sırtınızda ve midenizde biriken fiziksel ağrılara dönüşüyor. Düşük enerji seviyeniz (3/10) ve kötü uyku kaliteniz (4/10), bedeninizin bu bastırılmış duygusal enerjiyi taşımaktan yorulduğunun kanıtıdır.\\n    *   **Altında Yatan Güdü:** Olumsuz duyguların \\"kötü\\" veya \\"tehlikeli\\" olduğuna dair derin bir inanç. Öfke, hayal kırıklığı gibi duyguları ifade etmenin ilişkileri yok edeceğinden korkuyorsunuz."}, {"id": "block-4", "content": "## İlişkiler ve Sosyal Dinamikler\\n\\nİlişki dünyanız, bahsettiğimiz temel çelişkinin sahnesidir. Yüksek empati ve uyumluluğunuzla insanları kendinize çekersiniz. Sıcak, anlayışlı ve iyi bir dinleyici olarak tanınırsınız. Ancak bu, madalyonun sadece bir yüzüdür.\\n\\nİlişki derinleştikçe, Kaçınmacı Bağlanma stiliniz devreye girer. Partneriniz daha fazla yakınlık ve bağlılık aradığında, siz kendinizi kapana kısılmış hissetmeye başlarsınız. Bu, \\"beni kısıtlıyor\\" düşüncesini tetikler. Tepkiniz, doğrudan bir iletişim kurmak yerine pasif-agresif davranışlar veya duygusal geri çekilme olur. Partneriniz bu mesafeyi hisseder ve daha fazla ilgi göstermeye çalışır, bu da sizi daha da boğar ve kaçma isteğinizi artırır. Bu, \\"takipçi-mesafeli\\" adı verilen klasik bir ilişki tuzağıdır ve sonu genellikle her iki taraf için de büyük bir hayal kırıklığıdır.\\n\\nÇatışma anlarında kaçınmacı stiliniz, sorunların çözülmeden halının altına süpürülmesine neden olur. Küçük anlaşmazlıklar birikir ve zamanla büyük bir kırgınlık dağına dönüşür. Sizin için \\"barışı korumak\\", aslında sorunların kangren olmasına izin vermektir."}, {"id": "block-5", "content": "## Kariyer ve Çalışma Tarzı\\n\\nMevcut durumunuz (\\"bir giriş elemanıyım ayrıca trendyol'dan satış yapmaya başladım\\") ve kişilik profiliniz arasında ciddi bir uyumsuzluk riski var.\\n\\nDISC profiliniz (Yüksek S/I, Düşük D/C), sizi mükemmel bir müşteri ilişkileri veya destek personeli yapar. İnsanlara yardım etmeyi, onlarla iyi ilişkiler kurmayı ve sadakat oluşturmayı seversiniz. Ancak bir girişimci veya işletme sahibi olmak, tam olarak zayıf olduğunuz alanları gerektirir: Baskınlık (D) ve Uygunluk (C).\\n\\nBir işletmeyi yönetmek; net kararlar almayı, risk üstlenmeyi, pazarlık yapmayı, standartları belirlemeyi ve bazen sevimsiz olmayı göze almayı gerektirir (Düşük D'nizin tam zıttı). Ayrıca, envanter takibi, finansal planlama, sipariş yönetimi gibi detaylı, sistematik ve kural bazlı işler gerektirir (Düşük C'nizin kabusu).\\n\\nBu yolda devam ederseniz, müşterilerinizle harika dostluklar kurabilir ama kâr etmeyen, büyümeyen ve sürekli operasyonel krizler yaşayan bir işletmeye sahip olabilirsiniz. \\"İstikrarlı olamama\\" ve \\"tembellik\\" olarak adlandırdığınız şeyler, aslında bu görevlerin doğanıza ne kadar aykırı olduğunun bir işaretidir. Başarılı olmak için bu alanları bilinçli olarak geliştirmeniz veya bu görevleri delege etmeniz şarttır."}, {"id": "block-6", "content": "## Duygusal Desenler ve Stres\\n\\nStres tepkiniz son derece nettir. Sizin için birincil tetikleyiciler **eleştirilmek, kontrol edilmek veya görmezden gelinmektir.** Bu durumlar yaşandığında, ilk tepkiniz duyguyu bastırmak ve durumu görmezden gelmektir (Kaçınma).\\n\\nAncak bedeniniz bu oyuna kanmaz. Zihniniz \\"sorun yok\\" derken, sinir sisteminiz \\"Savaş/Kaç\\" moduna geçer. Omuzlarınız gerilir, sırtınız ağrır, mideniz kasılır. Bu, bastırdığınız öfke veya hayal kırıklığının fiziksel çığlığıdır. Bu kronik alarm durumu, enerji seviyenizi tüketir, uykunuzu sabote eder ve sizi sürekli yorgun ve gergin bırakır. \\"Orta Düzey Stres\\" (7/10) olarak belirttiğiniz seviye, sizin için artık \\"normal\\" hale gelmiş bir kriz durumudur. Bedeniniz, zihninizin ifade etmeyi reddettiği savaşı veriyor."}, {"id": "block-7", "content": "## Yaşam Desenleri ve Muhtemel Tuzaklar\\n\\nBu profille, hayatınızda tekrarlayan bir desen görmeniz muhtemeldir: **Potansiyelin Eşiğinde Takılıp Kalma.** Yüksek gelecek umudunuzla (FTP) yeni heveslere ve projelere (Trendyol işi gibi) başlarsınız. Başlangıçtaki sosyal ve heyecan verici kısımları seversiniz (Yüksek I). Ancak proje, disiplin, yapı ve potansiyel çatışma (örneğin, bir tedarikçiyle pazarlık yapmak) gerektirdiğinde, ilginizi kaybeder ve geri çekilirsiniz (Düşük C ve D). Sonuç olarak, birçok \\"başlanmış ama bitirilmemiş\\" proje ve \\"keşke\\" ile dolu bir geçmiş biriktirme riskiyle karşı karşıyasınız.\\n\\nEn büyük tuzağınız, mutluluğunuzun ve başarınızın önündeki engelin dışsal olduğuna inanmaktır: \\"Eşim izin verse...\\", \\"İnsanlar beni dinlese...\\", \\"Şartlar farklı olsa...\\". Gerçekte ise en büyük engel, özerklik korkunuzla inşa ettiğiniz içsel kafestir. Kendi kendinize koyduğunuz bu sınırlar, başkalarının size koyabileceği tüm sınırlardan daha kısıtlayıcıdır."}, {"id": "block-8", "content": "## Yol Ayrımınız: İki Muhtemel Gelecek\\n\\nBugünkü analize dayanarak, önümüzdeki 5 yıl için iki farklı senaryo öngörebiliriz. Hangi yolda yürüyeceğiniz tamamen sizin seçiminizdir.\\n\\n**Yol 1: 'Aynen Devam' Geleceği**\\n\\nBu yolda, temel dinamiklerinizi değiştirmek için hiçbir şey yapmazsınız. Çatışmadan kaçınmaya, duygularınızı bastırmaya ve yakınlıktan korkmaya devam edersiniz. Trendyol işiniz, ara sıra ilgilendiğiniz bir hobi olarak kalır, çünkü büyümek için gereken zorlu kararları almaktan kaçınırsınız. İlişkinizde, eşinize karşı birikmiş kırgınlık sessizce büyür. Kendinizi giderek daha fazla \\"kurban\\" gibi hisseder, \\"pasif ve korkak\\" olduğunuza dair inancınızı pekiştirirsiniz. Kronik stres, fiziksel sağlığınızı daha fazla etkilemeye başlar; sırt ve mide ağrıları hayatınızın bir parçası olur. 5 yıl sonra, bugün hayalini kurduğunuz \\"kendi ayakları üzerinde duran kadın\\" olmaktan daha da uzakta olduğunuzu fark edersiniz. Otomatik araba, bir özgürlük sembolü değil, ulaşılamamış bir hayal olarak kalır.\\n\\n**Yol 2: 'Potansiyel' Geleceği**\\n\\nBu yolda, bugünü bir dönüm noktası olarak kabul edersiniz. Kör noktalarınızla yüzleşme cesaretini gösterirsiniz. Küçük adımlarla, sağlıklı sınırlar koymayı öğrenirsiniz. Eşinize ihtiyaçlarınızı suçlayıcı bir dille değil, \\"Benim ...'ya ihtiyacım var\\" gibi net ifadelerle anlatmaya başlarsınız. Bu başlangıçta korkutucu olur ama her denemede özgüveniniz artar. Trendyol işiniz için bir sistem kurarsınız; her gün sadece 1 saat ayırarak disiplin kasınızı geliştirirsiniz. Düşük Baskınlık (D) özelliğinizi, \\"agresif olmak\\" yerine \\"kararlı olmak\\" olarak yeniden çerçevelersiniz. Duygularınızı bastırmak yerine, onları birer sinyal olarak görmeyi öğrenirsiniz. 5 yıl sonra, sadece kâr eden bir işe değil, aynı zamanda kendine saygısı olan bir kadına dönüşürsünüz. İlişkiniz, karşılıklı saygıya dayalı daha dengeli bir ortaklığa evrilir. Ve o otomatik arabayı aldığınızda, bu sadece bir ulaşım aracı değil, kendi iradenizle inşa ettiğiniz yeni hayatınızın bir zafer anıtı olur."}, {"id": "block-9", "content": "## Uygulanabilir İlerleme Yolu\\n\\nDeğişim, büyük ve soyut kararlarla değil, küçük, somut ve tutarlı eylemlerle gerçekleşir. İşte başlangıç için 10 adımlık stratejiniz:\\n\\n1.  **\\"Hayır\\" Kasını Geliştirin:** Bu hafta, size hiçbir faydası olmayan üç küçük ve önemsiz şeye \\"hayır\\" deyin. Bir arkadaşınızın anlamsız bir isteği, size uymayan bir plan... Sadece sonuçları görmek için \\"hayır\\" deme alıştırması yapın. Dünyanın başınıza yıkılmadığını göreceksiniz.\\n\\n2.  **\\"Ben Dili\\" ile İhtiyaç Bildirimi:** \\"Sen sürekli beni eleştiriyorsun\\" yerine, \\"Bana bu şekilde konuştuğunda kendimi değersiz hissediyorum ve senden daha yapıcı bir dil kullanmanı rica ediyorum\\" demeyi deneyin. Suçlamayı bırakıp kendi duygunuzun ve ihtiyacınızın sorumluluğunu alın.\\n\\n3.  **Yapısal Zaman Blokları Oluşturun:** Her gün, takviminize \\"Trendyol Saati\\" olarak 30 dakikalık, pazarlık kabul etmez bir blok koyun. O 30 dakika boyunca sadece işle ilgili bir şey yapın. Amaç satış yapmak değil, tutarlılık alışkanlığı kazanmaktır.\\n\\n4.  **Somatik Boşalma Ritüeli:** Gün sonunda veya stres hissettiğinizde, omuzlarınızdaki ve boynunuzdaki gerilimi fark edin. 5 dakika boyunca omuzlarınızı silkeleyin, başınızı yavaşça çevirin, esneyin. Bedeninizde biriken stresi bilinçli olarak serbest bırakın.\\n\\n5.  **\\"Zihin Okuma\\" Varsayımını Sorgulayın:** Birinin sizi yanlış anladığını veya eleştirdiğini düşündüğünüzde, durun ve kendinize sorun: \\"Bu kişinin niyetinin bu olduğuna dair %100 kanıtım var mı? Başka hangi olası açıklamalar olabilir?\\" Varsaymak yerine soru sorun.\\n\\n6.  **Özerklik Anlarını Belirleyin ve Koruyun:** \\"Kendim olmak\\" sizin için ne anlama geliyor? Yazlıkta veya maç izlerken neyi farklı yapıyorsunuz? Bu davranışları (belki de sadece rahatça oturmak veya düşüncelere dalmak) haftalık rutininize bilinçli olarak ekleyin. Bu, \\"eşimden kaçış\\" değil, \\"kendime dönüş\\" zamanı olmalı.\\n\\n7.  **Değerlerinizi Önceliklendirin:** Size verilen 10 değerden sadece üçünü seçmek zorunda olsaydınız, hangileri olurdu? Hayatınızı bu ilk üç değere göre mi yaşıyorsunuz? Yaşamıyorsanız, hangi küçük değişiklikleri yapabilirsiniz?\\n\\n8.  **Duygu Günlüğü Tutun:** Sadece bir hafta boyunca, her gün sonunda sizi en çok zorlayan duyguyu (öfke, hayal kırıklığı, endişe) yazın. Onu bastırmak yerine sadece adını koyun. \\"Bugün kırgınlık hissettim.\\" Bu, duyguları tanıma ve kabul etme yolunda ilk adımdır.\\n\\n9.  **Gelecek Perspektifinizi Eyleme Dökün:** O otomatik arabayı bir hedef olarak alın. Fiyatını araştırın. Ayda ne kadar kenara koymanız gerektiğini hesaplayın. Hayali, bir plana dönüştürün. Bu, umudunuzu somut bir stratejiye bağlayacaktır.\\n\\n10. **Profesyonel Yardım Almayı Düşünün:** Kaçınmacı Bağlanma gibi derin köklü bir kalıbı tek başına kırmak son derece zordur. Bir terapist, bu kalıpların kökenini anlamanıza ve sağlıklı ilişki kurma becerileri geliştirmenize yardımcı olabilir. Bu bir zayıflık değil, stratejik bir güç hamlesidir."}, {"id": "block-10", "content": "## Kendi Sözlerinizden: Anılar ve Anlam\\n\\nPaylaştığınız anılar, kişilik profilinizin sadece bir doğrulaması değil, aynı zamanda onun duygusal haritasıdır. Bu anıları neden seçtiğiniz, kim olduğunuz hakkında test sonuçlarından çok daha fazlasını söyler.\\n\\n*   **Ana Anlatı Temaları:**\\n    *   **Özgürlük ve Tutsaklık Çatışması:** Bu, anlatınızın bel kemiğidir. Bir yanda \\"kendi başına trafiğe çıkmak\\" gibi mutlak bir özerklik ve başarı anı var. Diğer yanda ise eşinizin varlığıyla \\"kendin olamama\\" hissi. Bu, Kaçınmacı Bağlanma stilinizin ve düşük Baskınlık puanınızın gerçek hayattaki tezahürüdür. Özgürlüğü yalnızlıkla, yakınlığı ise boğulmayla eşleştiriyorsunuz.\\n    *   **Pasifliğin Getirdiği Pişmanlık (Kirlenme Anlatısı):** \\"Bu kadar pasif ve korkak olmasaydım. Keşke okusaydim...\\" cümleniz, potansiyeli olan iyi bir hayatın, eylemsizlik nedeniyle lekelendiği bir \\"kirlenme anlatısıdır\\". Bu, sadece bir pişmanlık değil, aynı zamanda kimliğinizin bir parçası haline gelmiş bir hikaye. Bu hikaye, mevcut durumunuzdaki sorumluluğunuzdan kaçmak için bir mazeret görevi görüyor olabilir.\\n    *   **Kayıp ve Yeniden Doğuş (Kefaret Anlatısı):** En acı verici anılarınızdan biri olan \\"Babamın ölümü\\", en mutlu anılarınızdan biriyle, \\"yeğenim Ahmet'in doğumu babamın vefatı sonrası ilaç gibi geldi\\" ifadesiyle dengeleniyor. Bu, klasik bir kefaret anlatısıdır: Kötü bir olay (kayıp), iyi bir olayın (yeni yaşam) ortaya çıkmasına neden olur ve bu da hayata bir anlam ve umut katar. Bu, sizin en zor zamanlarda bile bir anlam ve bağlantı bulma kapasitenizi gösterir ve yüksek empati puanınızla tamamen uyumludur.\\n\\nBu anılar, mücadelenizin özünü ortaya koyuyor: Bir yanınız, babanızın kaybından sonra bir yeğenle yeniden hayata tutunacak kadar derin bağlar kurmak istiyor. Diğer yanınız ise, bir eşin varlığında bile kendini kaybedeceğinden korkacak kadar özerkliğine düşkün. Mevcut Anlam ve Amaç Puanınızın orta düzeyde (%67) olması şaşırtıcı değil. Hayatınızda hem derin anlam kaynakları (aile, sevgi) hem de anlamı baltalayan derin çatışmalar (özgürlük vs. yakınlık) bir arada bulunuyor. İlerlemenin yolu, bu iki ihtiyacın birbiriyle savaşmak zorunda olmadığını anlamaktan geçiyor: Hem derin bir bağ kurup hem de \\"kendiniz\\" olabileceğiniz bir yaşam inşa edebilirsiniz. Ama bu, önce sınırları, iletişimi ve kendine saygıyı öğrenmeyi gerektirir."}, {"id": "block-11", "content": "## Bulgular, Temeller ve Kanıtlar\\n\\nBu analiz, size anlık bir fikir vermek için değil, psikolojik ölçüm araçlarından elde edilen verileri bütüncül bir şekilde yorumlamak için tasarlanmıştır. Vardığımız sonuçlar, birden fazla güvenilir teorik çerçeveye dayanmaktadır.\\n\\nTemel kişilik yapınız, on yıllardır yaygın olarak kullanılan iki model olan Myers-Briggs Tip Göstergesi (MBTI) ve Beş Faktörlü Kişilik Modeli (Big Five) kullanılarak analiz edilmiştir. MBTI, bilgi işleme ve karar verme tercihlerinizi (INFP) ortaya koyarken, Big Five, temel mizaç özelliklerinizi (yüksek Uyumluluk, orta düzeyde Duygusal Dengesizlik gibi) sayısal olarak ölçmüştür. Davranışsal eğilimleriniz ve çalışma tarzınız, insanların çevreleriyle nasıl etkileşime girdiğini dört temel boyutta (Baskınlık, Etkileyicilik, Sadakat, Uygunluk) inceleyen DISC modeliyle haritalandırılmıştır.\\n\\nİlişki dinamikleriniz, John Bowlby'nin Bağlanma Teorisi temel alınarak incelenmiştir. Verdiğiniz yanıtlar, erken dönem ilişkilerinizde oluşan ve yetişkinlikteki romantik ilişkilerinizi derinden etkileyen bir bağlanma modelini (Kaçınmacı) işaret etmektedir. Duygu düzenleme, çatışma stilleri ve empati gibi sosyal-duygusal yetkinlikleriniz, bu alanlardaki yerleşik araştırma modellerine dayalı olarak değerlendirilmiştir.\\n\\nSon olarak, bilişsel alışkanlıklarınız (Bilişsel Çarpıtmalar), yaşama bakış açınız (Gelecek Zaman Perspektifi, Anlam ve Amaç) ve zihin-beden bağlantınız (Somatik Farkındalık) da analize dahil edilerek, sadece kim olduğunuzun değil, aynı zamanda dünyayı nasıl deneyimlediğinizin ve geleceğe nasıl baktığınızın çok katmanlı bir portresi oluşturulmuştur. Kendi sözlerinizle paylaştığınız anılar, bu nicel verileri doğrulamak ve onlara derinlik katmak için kullanılmıştır."}, {"id": "block-12", "content": "## Yasal Uyarı\\n\\nBu rapor yalnızca kişisel gelişim ve bilgilindirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır."}]	2025-08-29 20:45:13.649121
a6cd3a3f-98c8-4577-95da-8f11004a4811	d87e115c-0d54-4bcc-9c17-773c43423f09	self	completed	\N	\N	\nHazır mısın? Başlayalım..\n\nBu, psikolojik eğilimlerinin, davranış kalıplarının ve gizli potansiyelinin derinlemesine bir analizidir. Bu rapor, seni rahat ettirmek için değil, seni daha güçlü kılmak için tasarlandı. Gerçeklerle yüzleşmek acı verici olabilir, ancak kalıcı değişim ancak bu yüzleşmeyle başlar. Şimdi, kim olduğuna ve kim olabileceğine dürüstçe bakalım.\n\n| Özellik / Boyut | Puan |\n|-------------------|-------|\n| **MBTI Tipi** | ISTJ |\n| MBTI Dışadönüklük (E) | 25% |\n| MBTI İçe dönüklük (I) | 75% |\n| MBTI Duyusal (S) | 60% |\n| MBTI Sezgisel (N) | 40% |\n| MBTI Düşünen (T) | 75% |\n| MBTI Hisseden (F) | 25% |\n| MBTI Yargılayan (J) | 80% |\n| MBTI Algılayan (P) | 20% |\n| **Big Five - Deneyime Açıklık (O)** | 88% |\n| **Big Five - Sorumluluk (C)** | 100% |\n| **Big Five - Dışadönüklük (E)** | 85% |\n| **Big Five - Uyumluluk (A)** | 80% |\n| **Big Five - Duygusal Dengesizlik (N)** | 88% |\n| **DISC - Hakimiyet (D)** | 30% |\n| **DISC - Etki (I)** | 0% |\n| **DISC - Kararlılık (S)** | 10% |\n| **DISC - Titizlik (C)** | 90% |\n| Bağlanma - Kaygı | 88% |\n| Bağlanma - Kaçınma | 88% |\n| Çatışma Stili (Birincil) | Rekabetçi |\n| Duygu Düzenleme - Yeniden Değerlendirme | 58% |\n| Duygu Düzenleme - Bastırma | 58% |\n| Empati - Duygusal İlgi | 65% |\n| Empati - Perspektif Alma | 45% |\n| Anlam ve Amaç Puanı | 58% |\n| Gelecek Zaman Perspektifi Puanı | 55% |\n| Baskın Bilişsel Çarpıtmalar | Ya Hep Ya Hiç Düşüncesi |\n| Mevcut Somatik Durum | Savaş/Kaç |\n\n## Temel Kişiliğin\n\nKişiliğinin temelinde sarsılmaz bir yapı ve düzen ihtiyacı yatıyor. Sen, **ISTJ (İçe dönük, Duyusal, Düşünen, Yargılayan)** olarak, dünyanın öngörülebilir, mantıklı ve kurallara dayalı olmasını bekleyen bir stratejistsin. Senin için gerçeklik, somut veriler, kanıtlanmış yöntemler ve yerine getirilmesi gereken sorumluluklardan oluşur. Soyut teoriler veya belirsiz duygularla pek işin olmaz; senin dünyan, neyin işe yaradığı ve neyin yaramadığı üzerine kuruludur. **Yüksek Sorumluluk (%100)** ve **Titizlik (DISC-C: %90)** puanların, bu yapının temel taşlarıdır. Bir işi üstlendiğinde, onu doğru, eksiksiz ve en yüksek standartlarda yapmak senin için bir onur meselesidir. Bu, seni inanılmaz derecede güvenilir bir problem çözücü yapar; nitekim kendi ifadenle gurur duyduğun şey de bu: "Benim olduğum yerde problem olmayacağını ve oluşan problemleri çözebileceğim konusunda verdiğim güven."\n\nAncak bu sağlam yapının içinde derin bir fırtına var. **Yüksek Duygusal Dengesizlik (%88)**, bu düzenli dünyanın en ufak bir sarsıntıda nasıl bir kaos alanına dönüşebileceğini gösteriyor. Kontrolü kaybettiğinde veya işler planlandığı gibi gitmediğinde – özellikle "bozulan iş durumu" gibi temel güvenlik algını sarsan durumlarda – içsel dengen altüst oluyor. Stres seviyenin 10 üzerinden 8 olması ve somatik durumunun sürekli bir **"Savaş/Kaç"** modunda takılı kalması bunun fiziksel kanıtlarıdır. Vücudun sürekli bir tehdit algılıyor ve bu gerilimi boynunda, omuzlarında ve midende biriktiriyor.\n\nBu içsel çatışma, seni bir arketipe dönüştürüyor: **Tahtını Kaybetmiş Kral.** Bir zamanlar "galericilik yaptığın dönemlerdeki" gibi gücünün ve yetkinliğinin zirvesindeydin. Krallığın, yani işin ve finansal istikrarın vardı. Problemleri çözer, düzeni sağlardın. Ancak 2003 ve 2015'teki işsizlik deneyimlerin, bu krallığı temelinden sarstı. Artık kendini bir kral gibi değil, tacı ve toprakları elinden alınmış, sürgündeki bir lider gibi hissediyorsun. "Finansal özgürlük" hedefin, sadece para kazanmak değil; kaybettiğin o krallığı, gücü ve özsaygıyı geri alma arayışıdır.\n\n## Güçlü Yönlerin\n\n*   **Sarsılmaz Sorumluluk Bilinci:** Üstlendiğin bir görevi yarım bırakmak veya baştan savma yapmak senin doğana aykırı. %100 Sorumluluk puanın, detaylara olan hakimiyetin ve işleri "doğru" yapma konusundaki ısrarınla birleştiğinde, seni özellikle kriz anlarında veya yüksek standartlar gerektiren projelerde vazgeçilmez kılıyor.\n*   **Aşırı Yüksek Standartlar ve Titizlik:** DISC profilindeki %90'lık Titizlik (C) skoru, kalite ve doğruluk konusundaki takıntılı hassasiyetini gösterir. Bu, hata payının düşük olması gereken alanlarda büyük bir avantajdır. Analitik düşünür, planlı hareket eder ve kurallara bağlılığınla öngörülebilirlik ve istikrar sağlarsın.\n*   **Pratik Problem Çözme Yeteneği:** Hayal dünyasında yaşamazsın. MBTI profilindeki 'Duyusal' (S) ve 'Düşünen' (T) özelliklerin, sorunlara somut, mantıksal ve adım adım çözümler bulmanı sağlar. İnsanlara "oluşan problemleri çözebileceğin" konusunda verdiğin güven tam olarak bu yeteneğinden kaynaklanır.\n*   **Ahlaki Cesaret:** Baskı altında bile doğru olanı yapma eğilimin var. Patronunun yalanına alet olmayıp mahkemede bir çalışanın hakkını savunman, değerlerinin ne kadar köklü olduğunu gösteriyor. Bu, yüzeysel bir uyumdan çok daha derin bir adalet duygusuna sahip olduğunu kanıtlar. Bu, nadir bulunan ve saygı duyulması gereken bir özelliktir.\n\n## Kör Noktalar ve Riskler\n\nBu güçlü yönlerin madalyonun sadece bir yüzü. Diğer yüzünde ise seni savunmasız bırakan ve potansiyelini sabote eden ciddi kör noktalar var.\n\n*   **Kalıp: Kırılgan Mükemmeliyetçilik.**\n    *   **Tanım:** Yüksek Sorumluluk ve Titizlik puanların, "Ya Hep Ya Hiç" bilişsel çarpıtmasıyla birleştiğinde zehirli bir kokteyle dönüşüyor. Senin için ya tam bir başarı vardır ya da tam bir fiyasko. Arası yoktur. Bir işte veya durumda %100 kontrol sağlayamadığında, bunu kısmi bir aksaklık olarak değil, kişisel bir yenilgi olarak algılarsın.\n    *   **Bedeli:** Bu düşünce yapısı, seni aşırı kırıngan yapar. İşsiz kalmak gibi hayatın doğal bir parçası olan zorluklar, senin için sadece bir gelir kaybı değil, kimliğinin ve değerinin tamamen yok olması anlamına gelir. Bu yüzden stres seviyen bu kadar yüksek ve hayat memnuniyetin bu kadar düşük. Bu zihniyet, esnekliği ve adaptasyonu imkansız hale getirir.\n    *   **Altında Yatan Dinamik:** Başarısızlık korkusu. Senin için başarısızlık, sadece bir sonuç değil, "yetersiz" olduğunun kanıtıdır. Bu yüzden her şeyi kontrol etmeye çalışırsın, çünkü kontrol edemediğin her şey potansiyel bir utanç ve değersizlik kaynağıdır.\n\n*   **Kalıp: Duygusal İzolasyon ve Yanlış Anlaşılma.**\n    *   **Tanım:** Düşük empati (Perspektif Alma: %45) ve yüksek Bağlanma Kaygısı/Kaçınması (%88), ilişkilerinde bir duvar örmene neden olur. Kendi mantıksal dünyanda o kadar yoğunsun ki, başkalarının – özellikle de eşinin – duygusal gerçekliğini anlamakta zorlanıyorsun. Onların tepkilerini kendi mantık süzgecinden geçiriyorsun ve sana "haksız" görünüyorlar.\n    *   **Bedeli:** Yalnızlık ve derin bir hayal kırıklığı. "Evlenmezdim" demen, bu birikmiş yanlış anlaşılmaların ve karşılanmamış duygusal ihtiyaçların bir patlamasıdır. Eşinin zor zamanlardaki tepkisini "haksız" olarak etiketlerken, onun korkusunu, güvensizliğini veya endişesini görmeyi başaramamış olabilirsin. Bu kör nokta, en yakın ilişkini zehirliyor ve seni en çok ihtiyaç duyduğun anda destek sisteminden mahrum bırakıyor.\n    *   **Altında Yatan Dinamik:** Savunmasızlık korkusu. Duygusal olarak açılmak, kontrolü kaybetmek ve incinmek demektir. Bu yüzden mantık ve kuralların arkasına saklanıyorsun. Başkalarının duygusal dünyasına girmek, kendi kontrol edemediğin duygularınla yüzleşmek anlamına gelir ki bu senin için en büyük tehditlerden biridir.\n\n*   **Kalıp: Geçmişe Takılıp Kalma.**\n    *   **Tanım:** Düşük Gelecek Zaman Perspektifi puanın (%55), zihninin geçmişin başarılarına ("galericilik dönemi") ve başarısızlıklarına ("işsiz kalmam") saplanıp kaldığını gösteriyor. Gelecek, "finansal özgürlük" gibi soyut bir hedef veya "finansal kölelik" gibi korkutucu bir senaryodan ibaret. Arada, bugünden oraya gidecek somut, umut dolu bir yol haritan yok.\n    *   **Bedeli:** Eylemsizlik ve umutsuzluk. Şu anki başa çıkma mekanizman "sorundan kaçınmak veya ertelemek". Bu, problem çözücü kimliğinle tam bir çelişki içinde. Ancak bu mantıklı, çünkü geleceğe dair net ve ulaşılabilir bir vizyonun olmadığında, bugünün sorunlarıyla boğuşmak anlamsız ve ezici gelir. Bu durum, düşük enerji seviyenin (%50) ve fiziksel hareketsizliğinin de temel nedenidir.\n    *   **Bilinçdışı Kazanç (İkincil Kazanç):** Bu "kaçınma" davranışının sana gizli bir faydası var. Kaçındığın ve ertelediğin sürece, başarısız olma ihtimaliyle yüzleşmek zorunda kalmazsın. "Eğer gerçekten deneseydim yapardım" bahanesini canlı tutarsın. Bu, her şeyi yapıp yine de başarısız olmanın getireceği o ezici utançtan seni koruyan bir kalkandır.\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişki dünyan, tam bir paradoks üzerine kurulu. Bir yanda güvenilirlik, sadakat ve sorumluluk var. Diğer yanda ise derin bir güvensizlik, reddedilme korkusu ve duygusal mesafe. **Kaygılı-Kaçınmacı (%88 Kaygı, %88 Kaçınma)** bağlanma stilin, bu dinamiğin temelini oluşturur. Hem yakınlık istersin hem de yakınlıktan ölümüne korkarsın.\n\nBu, en net şekilde evliliğinde ortaya çıkıyor. Eşinin zor zamanlardaki tepkilerini "haksız" olarak görmen, kaygılı tarafının "Beni sevmiyor, beni terk edecek" korkusunu tetiklemiş. Buna karşılık kaçınmacı tarafın ise "İşte gördün mü, kimseye güvenilmez, en iyisi duvarlarımı örmek" diyerek devreye girmiş. "Evlenmezdim" ifaden, bu kaçınmacı parçanın nihai savunma mekanizmasıdır: "Eğer en başta bu ilişkiye girmeseydim, bu acıyı yaşamazdım."\n\n**Rekabetçi çatışma stilin**, anlaşmazlıkları bir kazanma-kaybetme savaşı olarak görmene neden oluyor. Haklı olmak, anlaşmaktan daha önemli hale geliyor. Düşük perspektif alma yeteneğinle birleştiğinde, bu durum partnerinin ne hissettiğini anlamanı engeller ve onu sadece "haksız" bir rakip olarak görmene yol açar. Bu, sevgi dolu bir ilişkiyi sürdürmek için sürdürülebilir bir strateji değildir; bu, bir yıpratma savaşıdır.\n\n## Kariyer ve Çalışma Tarzı\n\nSenin için iş, sadece bir gelir kapısı değil, bir kimlik ve değer kaynağıdır. **Yüksek Titizlik (C) ve orta düzey Hakimiyet (D)** kombinasyonu, seni kuralların, prosedürlerin ve net hedeflerin olduğu yapılandırılmış ortamlar için ideal bir çalışan veya yönetici yapar. Kalite kontrol, denetim, lojistik, mühendislik veya zanaatkarlık gibi alanlarda parlarsın. "Galericilik" dönemin muhtemelen bu yapı ve kontrol ihtiyacını karşılıyordu: arabanın mekaniği, satış süreci, finansal hedefler... hepsi somut ve ölçülebilirdi.\n\nEmeklilik veya işsizlik, bu nedenle senin için bir boşluk değil, bir kimlik krizidir. Değerini kanıtladığın ana sahne elinden alınmıştır. "Bozulan iş durumu" sadece finansal bir sorun değil, varoluşsal bir tehdittir. "Finansal özgürlük" hedefin, bu kaybolan statüyü ve kontrolü geri alma çabasıdır. Ancak mevcut kaçınma stratejilerin ve geçmişe takılıp kalman, bu hedefe ulaşmanı aktif olarak engelliyor.\n\n## Duygusal Desenler ve Stres\n\nStres tepkin son derece öngörülebilir ve fizikseldir.\n*   **Tetikleyiciler:** Kontrol kaybı, finansal belirsizlik, kuralların ihlal edilmesi ve en önemlisi, değersizlik veya yetersizlik hissi. Eşinden gelen "haksız" tepkiler, bu değersizlik hissini tetiklediği için bu kadar yıkıcı olmuştur.\n*   **Varsayılan Tepki:** Zihnin anında "Ya Hep Ya Hiç" moduna geçer. Durumu bir felaket olarak çerçeveler. Vücudun anında "Savaş/Kaç" moduna girer, adrenalin ve kortizol pompalar. Bu, boyun, omuz ve mide kaslarının kasılmasına, uyku kalitenin düşmesine (3/10) ve genel enerji seviyenin tükenmesine yol açar.\n*   **Başa Çıkma Stratejisi:** Duygularını hem **bastırmaya** hem de farklı bir açıdan bakmaya (**yeniden değerlendirme**) çalıştığını görüyoruz (puanlar eşit). Ancak bu çabalar, altta yatan felaket senaryosu tarafından boşa çıkarılıyor. Sonuç olarak, bunalmış hissediyor ve nihai başa çıkma yöntemin olan **"sorundan kaçınmaya"** başvuruyorsun. Bu, kısa vadede acıyı uyuşturan ama uzun vadede sorunu daha da büyüten bir stratejidir.\n\n## Yaşam Kalıpları ve Muhtemel Tuzaklar\n\nSenin gibi bir profile sahip insanlar için hayat, genellikle öngörülebilir bir döngüde ilerler:\n1.  **İnşa Etme Evresi:** Yüksek sorumluluk ve titizlikle, hayatlarında düzenli ve istikrarlı bir yapı (kariyer, aile, finansal güvenlik) kurarlar. Bu, senin "galericilik" dönemin gibi bir altın çağdır.\n2.  **Kırılma Evresi:** Hayatın kaçınılmaz bir krizi (iş kaybı, sağlık sorunu, ilişki çatışması) bu yapıyı sarstığında, esneklik gösteremezler. Kontrol kaybı, kimlik kaybı olarak deneyimlenir.\n3.  **İçe Kapanma Evresi:** "Ya Hep Ya Hiç" düşüncesiyle durumu tam bir yenilgi olarak yorumlarlar. Geçmişe özlem duyar, gelecekten umudu keserler. Kaçınma, izolasyon ve depresif eğilimler baş gösterir.\n\nSen şu anda net bir şekilde 3. evredesin. En büyük tuzağın, "Tahtını Kaybetmiş Kral" kimliğine sıkı sıkıya sarılmaktır. Geçmişteki gücünü ve başarını bir anıt gibi zihninde taşıyarak bugünün gerçekliğiyle yüzleşmekten kaçınırsan, hayatının geri kalanını bir hayal kırıklığı ve pişmanlık içinde geçirme riskin çok yüksek. Düşük Gelecek Zaman Perspektifin, bu tuzağa düşme olasılığını artırıyor, çünkü seni geçmişe zincirliyor.\n\n## Yol Ayrımı: İki Muhtemel Gelecek\n\nÖnümüzdeki 5 yıl için iki farklı yol var. Hangisini seçeceğin, bugünkü kararlarına bağlı.\n\n*   **Yol 1: "Olduğu Gibi" Geleceği.**\n    Eğer mevcut kalıpları değiştirmek için hiçbir şey yapmazsan, önümüzdeki 5 yıl, bugünün bir tekrarı olacak, sadece daha da kötüleşerek. Stres kronikleşecek, bu da ciddi fiziksel sağlık sorunlarına (yüksek tansiyon, sindirim problemleri, kalp rahatsızlıkları) yol açacak. Fiziksel hareketsizliğin devam edecek, enerjin daha da düşecek. Eşinle arandaki duygusal mesafe bir uçuruma dönüşecek; aynı çatı altında yaşayan iki yabancı olacaksınız. "Finansal özgürlük" hedefi, ulaşılamaz bir hayal olarak kalacak ve yerini "finansal kölelik" korkusunun yarattığı sürekli bir kaygıya bırakacak. Hayata küsmüş, geçmişin gölgesinde yaşayan, potansiyelini toprağa gömmüş, öfkeli ve yalnız bir adam olacaksın.\n\n*   **Yol 2: "Potansiyel" Geleceği.**\n    Eğer bu raporu bir uyandırma servisi olarak kabul eder ve harekete geçersen, 5 yıl içinde bambaşka bir gerçeklik mümkün. "Ya Hep Ya Hiç" düşüncesini terk edip daha esnek ve merhametli bir zihniyet geliştirdiğinde, işsizliği bir kimlik yıkımı olarak değil, bir geçiş dönemi olarak görmeye başlarsın. Bedeninin sinyallerini dinlemeyi öğrenir, küçük adımlarla (yürüyüş gibi) "Savaş/Kaç" modundan çıkarsın. Eşinin "haksız tepkilerinin" ardındaki korkuyu anlamaya çalıştığında, ilişkinizde on yıllardır eksik olan bir anlayış ve şefkat kapısı aralanır. Kimliğini sadece "sağlayıcı" rolü üzerine değil, ahlaki gücün (mahkeme anısı gibi), bilgeliğin ve dayanıklılığın üzerine yeniden inşa edersin. Finansal durumun belki eskisi gibi olmayacak, ama zihinsel özgürlüğe kavuştuğun için bu artık değerinin tek ölçütü olmayacak. Tahtını kaybetmiş bir kral olmak yerine, bilgeliğiyle yol gösteren bir "Kralın Danışmanı" olursun. Gücün, artık kontrol etmekten değil, uyum sağlamaktan ve anlam bulmaktan gelir.\n\n## Eyleme Geçirilebilir İleriye Dönük Yol Haritası\n\nDeğişim, büyük ve soyut kararlarla değil, küçük, somut ve tutarlı eylemlerle gerçekleşir. İşte başlangıç için 10 adımlık yol haritan:\n\n1.  **"Savaş/Kaç" Döngüsünü Kır:** Her gün, sadece 15 dakika tempolu yürü. Amaç spor yapmak değil, vücudunda biriken stres hormonlarını (kortizol, adrenalin) yakmak ve sinir sistemini "güvenli" moda geçirmektir. Bu, müzakere edilemez bir önceliktir.\n2.  **"Ya Hep Ya Hiç" Düşüncesine Meydan Oku:** Her günün sonunda, "tamamen başarısız" bir gün olsa bile, tamamladığın veya doğru yaptığın ÜÇ küçük şeyi yaz. "Yatağımı topladım," "faturayı ödedim," "15 dakika yürüdüm." Zihnini grinin tonlarını görmeye yeniden programla.\n3.  **Geçmişi Analiz Et, Geleceği Planla:** Eşinle bir konuşma planla. Ama bu sefer suçlama veya savunma olmasın. Sadece şu soruyu sor: "2003 ve 2015'te işsiz kaldığımda, en çok neden korkmuştun?" Onun perspektifini anlamaya çalış. Bu, on yıllık bir düğümü çözebilir.\n4.  **Güç Tanımını Yeniden Yaz:** Gücün sadece finansal başarıdan gelmediğini kendine kanıtla. Patronuna karşı verdiğin o ahlaki duruşu düşün. O anki gücünü hatırla. Değerini, banka hesabınla değil, karakterinle ölçmeye başla.\n5.  **Kontrol Edebileceklerine Odaklan:** "Bozulan iş durumu" gibi kontrolün dışındaki şeylere odaklanmak yerine, bugün kontrol edebileceğin tek bir şeye odaklan. Bu, beslenmen, yürüyüşün veya bir bütçe planı yapmak olabilir. Kontrol alanını yeniden ele geçir.\n6.  **"Finansal Özgürlük" Hedefini Parçalara Ayır:** Bu hedef çok büyük ve ezici. Onu küçült. Bu ay için ulaşılabilir ilk adım ne? "Tüm borçlarımı listelemek," "bir finansal danışmanla görüşmek için randevu almak," "gereksiz bir aboneliği iptal etmek." Büyük hedefler, küçük adımlarla fethedilir.\n7.  **Kaçınma Davranışını Yakala:** Bir sorundan kaçındığını veya ertelediğini fark ettiğinde, dur ve kendine sor: "Şu anda hangi duygudan kaçıyorum?" Korku mu? Utanç mı? Yetersizlik mi? Duyguyu isimlendirmek, onun üzerindeki gücünü azaltır.\n8.  **Bedenindeki Stresi Serbest Bırak:** Boynun, omuzların ve miden gergin olduğunda, bu bilinçli bir kararla olmaz. Günde birkaç kez durup bu bölgeleri bilinçli olarak gevşetmeye çalış. Omuzlarını indir, derin bir nefes al ve karın kaslarını serbest bırak. Vücuduna güvende olduğunu öğret.\n9.  **Perspektif Alma Egzersizi:** Bir dahaki sefere biriyle (özellikle eşinle) anlaşmazlığa düştüğünde, haklı çıkmaya çalışmak yerine 1 dakika dur ve şunu düşün: "Eğer onun yerinde olsaydım, bu durumu nasıl görürdüm? Onun için neyin önemli olduğunu düşünüyorum?" Bu, empati kasını geliştirir.\n10. **Anlam Kaynaklarını Çeşitlendir:** Hayattaki anlam ve amacın tek bir kaynağa (iş) bağlı olduğunda, o kaynak kuruduğunda sen de kurursun. Çocuklarınla ilişkin, ahlaki duruşun, belki de edindiğin tecrübeleri paylaşabileceğin bir gönüllülük işi... Yeni anlam kaynakları bul.\n\n## Kendi Sözlerinle: Anılar ve Anlam\n\nAnlattığın hikayeler, rastgele anılar değil; onlar kimliğinin temelini oluşturan mitlerdir. Bu hikayeleri analiz ettiğimizde, hayatını şekillendiren ana anlatıyı görüyoruz: **Kirlenme (Contamination) Anlatısı.** Bu anlatı türünde, iyi başlayan olaylar (evlilik, başarılı bir kariyer) kaçınılmaz olarak kötü bir olayla (ihanet, iş kaybı) lekelenir ve mahvolur.\n\n*   **Zirve ve Düşüş:** En canlı anın, "galericilik yaptığın dönemler" – yani gücünün ve kontrolünün zirvesi. En karanlık anların ise 2003 ve 2015'te işsiz kalman ve bu düşüş anlarında "eşinden gördüğün haksız tepkiler." Bu iki olay, senin için sadece birer talihsizlik değil, temel bir ihanet ve aşağılanma deneyimi. Bu anılar, "Başarısızlık" ve "Güvensizlik/Kötüye Kullanılma" şemalarını zihnine kazımış. Mevcut yüksek bağlanma kaygın ve kaçınman, bu derin yaraların doğrudan bir sonucudur.\n*   **Anıların Seçimi:** Bu anıları seçtin çünkü onlar senin temel çatışmanı özetliyor: Güçlü, başarılı, problem çözen adam ile yenilmiş, ihanete uğramış kurban arasındaki savaş. "Evlilik, çocuklarımın doğumu, patronumun verdiği para ödülü" gibi mutlu anılar bile, sonrasında gelen kayıpların gölgesinde kalıyor. "Evlenmezdim" demen, bu kirlenme anlatısının en trajik ifadesidir; başlangıçtaki iyi olayı (evlilik) bile sonradan gelen acıyla tamamen kirletip yok sayıyorsun.\n*   **Anlam Arayışı ve Çelişki:** Düşük Anlam ve Amaç Puanın (%58), bu kirlenme anlatısıyla doğrudan bağlantılı. Hayat hikayen sana sürekli olarak "ne kadar çabalarsan çabala, sonunda her şey mahvolacak" mesajını veriyor. Bu, bir amaç duygusu geliştirmeyi neredeyse imkansız kılıyor. Ancak bir umut ışığı var: Patronuna karşı mahkemede verdiğin ifade. Bu, bir **Kurtuluş (Redemption)** anısıdır. Kötü bir durumdan (ahlaksız bir talep) iyi bir sonuç (adaletin yerini bulması) çıkardın. Bu anı, senin kirlenme anlatına meydan okuyan tek güçlü kanıt. Senin görevin, hayatının ana temasını bu tekil kurtuluş anısı etrafında yeniden yazmaktır.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, keyfi yorumlara değil, psikoloji biliminin yerleşik teorik çerçevelerine dayanmaktadır. Kişilik yapını anlamak için **Beş Faktör Kişilik Modeli (Big Five)** ve **Myers-Briggs Tip Göstergesi (MBTI)** kullanılmıştır. Bu modeller, on yıllardır süren araştırmalarla desteklenen, bireylerin düşünce, duygu ve davranışlarındaki istikrarlı kalıpları tanımlar. Davranışsal eğilimlerini ve çalışma tarzını netleştirmek için **DISC modeli** entegre edilmiştir.\n\nİlişki dinamiklerin, **John Bowlby ve Mary Ainsworth'ün Bağlanma Teorisi** üzerinden analiz edilmiştir. Bu teori, erken çocukluk deneyimlerimizin yetişkinlikteki romantik ilişkilerimizi nasıl şekillendirdiğini açıklar. Yüksek kaygı ve kaçınma puanların, güvensiz bir bağlanma stiline işaret etmektedir. Duygusal ve bilişsel kalıpların, **Bilişsel Davranışçı Terapi (BDT)** ilkeleriyle incelenmiştir. Özellikle "Ya Hep Ya Hiç" gibi bilişsel çarpıtmaların ve bunların stres seviyen üzerindeki etkileri bu çerçevede değerlendirilmiştir.\n\nHayata dair anlam ve amaç arayışın, **Viktor Frankl'ın Logoterapi** yaklaşımıyla ele alınmıştır. Geleceğe bakış açın ise **Philip Zimbardo'nun Zaman Perspektifi Teorisi** ile değerlendirilmiştir. Son olarak, stresin bedensel yansımaları, **Stephen Porges'in Polivagal Teorisi** ışığında yorumlanarak, zihinsel durumun ile fiziksel sağlığın arasındaki ayrılmaz bağ ortaya konmuştur. Bu bütüncül yaklaşım, seni tek bir boyuta indirgemeden, birbiriyle etkileşim halindeki karmaşık bir sistem olarak anlamayı hedefler.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilindirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.\n\nBu rapor yalnızca kişisel gelişim ve bilgilendirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.\n	\N	\N	0	2025-08-25 02:31:17.537982+03	2025-08-25 02:31:17.537982+03	{"source": "manual_insert", "mbti_type": "ISTJ", "user_email": "niyazisucu@gmail.com"}	\N	\N	\N	\N	2025-08-29 20:45:13.649121
5fe17013-d742-41a8-8423-a2a085f8e6d9	9fa8e776-9698-4c17-8c08-09126d5a2b85	self	completed	\N	\N	Hazır mısın? Başlayalım..\n\nBu, verilerine dayanan stratejik bir analizdir. Amacımız seni iyi hissettirmek değil, daha güçlü ve etkili kılmaktır. Bazı kısımlar rahatsız edici olabilir; bu, değişimin başlangıcıdır. Şimdi, gerçeklerle yüzleşme zamanı.\n\n| Nitelik / Boyut | Puan |\n|--------------------------------------|--------------------------------|\n| **MBTI Tipi** | ESFJ |\n| MBTI Dışadönüklük (E) | 80% |\n| MBTI İçedönüklük (I) | 20% |\n| MBTI Duyumsama (S) | 60% |\n| MBTI Sezgi (N) | 40% |\n| MBTI Düşünme (T) | 20% |\n| MBTI Hissetme (F) | 80% |\n| MBTI Yargılama (J) | 60% |\n| MBTI Algılama (P) | 40% |\n| **Big Five - Açıklık (O)** | 62.5% |\n| **Big Five - Sorumluluk (C)** | 50% |\n| **Big Five - Dışadönüklük (E)** | 75% |\n| **Big Five - Uyumluluk (A)** | 62.5% |\n| **Big Five - Nevrotiklik (N)** | 62.5% |\n| **DISC - Baskınlık (D)** | 40% |\n| **DISC - Etki (I)** | 70% |\n| **DISC - Kararlılık (S)** | 35% |\n| **DISC - Uygunluk (C)** | 50% |\n| Bağlanma - Kaygı | 75% |\n| Bağlanma - Kaçınma | 58.3% |\n| Çatışma Stili (Birincil) | Kaçınmacı |\n| Duygu Düzenleme - Yeniden Değerlendirme | 58.3% |\n| Duygu Düzenleme - Bastırma | 50% |\n| Empati - Duygusal İlgi | 41.7% |\n| Empati - Perspektif Alma | 50% |\n| Anlam ve Amaç Puanı | 75% |\n| Gelecek Zaman Perspektifi Puanı | 68.8% |\n| Baskın Bilişsel Çarpıtmalar | Aşırı Genelleme |\n| Mevcut Somatik Durum | Savaş/Kaç |\n\n## Temel Kişiliğin\nSenin temel yapın, insanlarla bağ kurmak ve onları etkilemek üzerine kurulu. **ESFJ** (Konsül) ve yüksek **Etki (I)** skorun, seni doğuştan sosyal, ikna edici ve başkalarının onayına değer veren biri yapıyor. Bu, "online satış" gibi bir alanda başarılı olmak için gereken ham maddeye sahip olduğun anlamına gelir: insanları kendine çekebilirsin. Ancak bu parlak yüzeyin altında, seni durduran ve enerjini tüketen ciddi çelişkiler var.\n\nEn büyük çelişki şu: Kişiliğin **Hissetme (F)** odaklı (%80) olmasına rağmen, gerçek empati becerin – başkalarının duygularını anlama ve onlarla rezonansa girme kapasiten – oldukça düşük (%41.7). Bu, bir "halk adamı" gibi görünürken, içten içe başkalarının duygusal yükünü taşıyacak enerjiden yoksun olduğun anlamına geliyor. İnsanlarla etkileşimlerin, seni beslemek yerine tüketiyor çünkü sıcakkanlılık rolünü oynuyorsun ama içsel kaynakların tükenmiş durumda.\n\nİkinci kritik sorun, %50'lik **Sorumluluk (Conscientiousness)** puanın. Bu, bir girişimci için ölümcül bir zayıflıktır. Fikirler üretebilir, insanları heyecanlandırabilirsin (yüksek Etki), ancak iş sıkıcı detaylara, takibe ve disiplinli çalışmaya geldiğinde bocalıyorsun. Bu, "işlerim iyi gitmiyor" demenin temel nedenidir. Stratejin var, ama siperlerde savaşacak askerin yok.\n\nYüksek **Nevrotiklik (%62.5)** ise bu ateşin üzerine benzin döküyor. Küçük başarısızlıkları felaketlere dönüştürüyor, kaygını körüklüyor ve zaten az olan yaşam enerjini emiyor. Bu, hayatının arka planında sürekli çalan bir alarm sireni gibi.\n\nTüm bunları birleştirdiğimizde ortaya çıkan arketip: **Tükenmiş Elçi**. Bir elçi gibi insanları bir araya getirme, etkileme ve bir davayı temsil etme potansiyeline sahipsin. Ancak krallığın (işin, ilişkilerin, iç dünyan) harabeye dönmüş durumda ve sen bu görevi yerine getirecek enerjiyi kaybetmişsin. Kendi potansiyelinden sürgün edilmiş bir elçisin.\n\n## Güçlü Yönlerin\n* **Sosyal Çekim Gücü:** Yüksek Dışadönüklük ve Etki skorların sayesinde insanları doğal olarak kendine çekersin. İkna kabiliyetin, doğru kullanıldığında en büyük sermayendir. Bu, satışın ve sosyal hayatın ön kapısını açan anahtardır.\n* **Uyum Arayışı:** Yüksek Uyumluluk ve Hissetme odaklı yapın, çatışmadan kaçınmanı ve pozitif ilişkiler kurma arzunu gösterir. İnsanlar senin yanında genellikle rahat hisseder çünkü tehditkar değilsin.\n* **İçsel Anlam Duygusu:** Mevcut zorluklarına rağmen, hayatın bir anlamı olduğuna dair inancın oldukça güçlü (%75). Bu, en karanlık zamanlarda bile tutunabileceğin bir çıpadır. Birçok insan bu çapadan yoksundur; bu senin gizli gücün.\n* **Gelecek Odaklılık:** Geleceği planlama ve düşünme yeteneğin (%68.8) var. Bu, mevcut durumdan çıkmak için bir rota çizebileceğin anlamına gelir. Sorun rotayı çizmek değil, o yolda yürümektir.\n\n## Kör Noktalar ve Riskler\n* **Duygusal Uyumsuzluk (Yüksek Hissetme vs. Düşük Empati):** Bu senin Aşil topuğun. Dışarıya "duygusal" bir insan imajı çiziyorsun, ancak gerçek empati kapasiten tükenmiş durumda. Bu, ilişkilerini yüzeysel ve yorucu hale getiriyor. İnsanlar senin samimiyetini sorgulayabilir, sıcaklığının bir performans olduğunu hissedebilirler. Bunun bedeli, kalabalıklar içinde derin bir yalnızlıktır. Bu durumun temel nedeni, kendi içsel kaosunu yönetmekle o kadar meşgul olman ki başkalarına ayıracak duygusal alanın kalmamasıdır.\n* **Sorumluluk Uçurumu (Hırs vs. Eylem):** Başarılı bir iş kurma arzun, tutarsız eylemlerinle doğrudan çelişiyor. %50'lik Sorumluluk puanın, bir girişimcinin envanterindeki en büyük yüktür. Bu bir karakter kusuru değil, ele alınmadığı takdirde başarısızlığı garanti eden stratejik bir darboğazdır. Belirttiğin "Erteleme" alışkanlığı bunun doğrudan bir sonucudur.\n* **Bir Yaşam Stratejisi Olarak Kaçınma:** İster bir ilişkide, ister bu ankette olsun, rahatsız edici bir durumla karşılaştığındaki varsayılan tepkin geri çekilmek ve konuyu kapatmak. Cevaplarındaki "boş ver", "istemiyorum", "no comment" ifadeleri bunun kanıtıdır. Bu, felaket bir stratejidir. İşte, zorlu bir müşteriyi aramaktan kaçınmak anlamına gelir. İlişkilerde, partnerini duvarlarla karşılamak demektir. **Bunun bilinçdışı getirisi nedir?** Seni reddedilmekten ve başarısızlıktan korur. Tam olarak dahil olmadığın bir oyunda, asla tam olarak kaybedemezsin. Ama bunun bedeli, yarım yaşanmış bir hayat, yarım kurulmuş bir iş ve asla derinleşmeyen ilişkilerdir.\n* **Fiziksel İhmal ve Bedensel Stres:** Bedenini, hayatının motoru olarak değil, stresinin bir deposu olarak kullanıyorsun. Sürekli "Savaş/Kaç" modunda olman ve omuzlarındaki/boynundaki ağrı, soyut kavramlar değil; bedeninin mevcut stratejinin sürdürülemez olduğuna dair çığlıklarıdır. "Hayat enerjini geri kazanma" hedefin, fiziksel durumunu ele almadan imkansızdır. Enerji, zihinsel bir illüzyon değildir; biyolojik bir gerçektir.\n\n## İlişkiler ve Sosyal Dinamikler\nİlişkilerdeki temel modelin, yüksek **Kaygılı (%75)** ve orta-yüksek **Kaçınmacı (%58.3)** bağlanma stilinle tanımlanıyor. Bu, "Korkulu-Kaçınmacı" bir örüntüdür. Yani, bir yandan yakınlık ve sevgiye derin bir özlem duyarken (kaygı), diğer yandan reddedilme ve incinme korkusuyla insanları kendinden uzak tutuyorsun (kaçınma).\n\nBu, bir "yaklaş-uzaklaş" dansına yol açar. Muhtemelen ilişkilere büyük bir hevesle başlarsın (Yüksek Dışadönüklük, Yüksek Etki), ancak işler ciddileşip duygusal risk arttığında duvarlarını örer ve geri çekilirsin. Birincil çatışma stilinin "Kaçınmacı" olması, sorunların konuşulmak yerine halının altına süpürülmesine neden olur. Bu, zamanla biriken bir zehirdir ve ilişkilerin sessizce ölmesine yol açar. 47 yaşında bekar olman, bu dinamiğin uzun vadeli bir sonucu olabilir.\n\n## Kariyer ve Çalışma Tarzı\nProfilin, satışın "ön cephesi" için mükemmel: ağ kurma, insanları etkileme, sunum yapma (Yüksek Etki, Yüksek Dışadönüklük). Ancak, işin "arka cephesi" için tamamen yetersiz: idari işler, detaylı takip, finansal yönetim, zorlu müşteri sorunlarını çözme (Düşük Sorumluluk, Düşük Kararlılık, Kaçınmacı Çatışma Stili).\n\nSen "fikir adamı"sın, "vitrin yüzü"sün. Ama "operasyon müdürü" veya "tahsilatçı" değilsin. Tek kişilik online satış işinde, bu rollerin hepsini üstlenmek zorundasın ve doğana aykırı olan kısımlarda başarısız oluyorsun. Bu sadece kişisel bir zayıflık değil, iş modelinde yapısal bir hatadır. Başarısızlık kaçınılmaz hale geliyor çünkü seni en çok zorlayan görevlerden kaçıyorsun.\n\n## Duygusal Desenler ve Stres\nYüksek Nevrotiklik, temel stres seviyeni belirliyor. Küçük bir aksilik, "Aşırı Genelleme" bilişsel çarpıtmanla birleşerek "bütün işim batıyor" gibi bir felaket senaryosuna dönüşüyor. Bu düşünce, bedenini anında "Savaş/Kaç" moduna sokuyor ve omuzlarındaki gerginlik artıyor.\n\nBu stresle başa çıkma yöntemin ise "Duygusal Yeme" ve "Kaçınma". Sorunla yüzleşmek yerine, yemek yiyerek veya sorunu görmezden gelerek anlık bir rahatlama arıyorsun. Bu, ölümcül bir geri bildirim döngüsü yaratır: Stres → Ye/Kaçın → İşler daha da kötüleşir → Daha fazla stres. Omuzlarındaki ağrı, bu kısır döngünün fiziksel kanıtıdır.\n\n## Yaşam Örüntüleri ve Muhtemel Tuzaklar\nHayatın muhtemelen, büyük bir hevesle başlanan (Yüksek Etki) ancak disiplinli takip eksikliği nedeniyle sönen projelerle doludur (Düşük Sorumluluk). İlişkilerde de benzer bir örüntü vardır: başlangıçta umut verici, ancak kaçınmacı doğan nedeniyle gerçek derinliğe ulaşamayan bağlar.\n\nGenel yaşam memnuniyetinin 10 üzerinden 3 olması, bu profilin doğal bir sonucudur. Doğal yeteneklerin (sosyal etki), kritik stratejik zayıflıkların (düşük sorumluluk, kaçınma) nedeniyle gerçek dünya başarısına dönüştürülemiyor. Potansiyelin ile gerçekliğin arasındaki bu uçurum, memnuniyetsizliğinin ve enerji kaybının ana kaynağıdır.\n\n## Yol Ayrımı: İki Olası Gelecek\nTüm bu analize dayanarak, önümüzdeki 5 yıl için iki gerçekçi senaryo çizelim.\n\n**Yol 1: 'Aynen Devam' Geleceği**\nBu yolda, temel dinamiklerini değiştirmek için hiçbir şey yapmazsın. 5 yıl sonra, online işin ya tamamen batmış ya da kronik bir stres ve minimal gelir kaynağı olmaya devam ediyor olacak. Bekar kalmaya veya bir dizi yüzeysel ilişki döngüsüne devam edeceksin. Hareketsiz yaşam tarzı ve kronik stres nedeniyle fiziksel sağlığın bozulmuş olacak. Aradığın "yaşam enerjisi", hayal kırıklığı ve teslimiyet katmanlarının altına daha da gömülmüş olacak. 52 yaşında, yaşından daha yaşlı hisseden ve potansiyelinin nereye gittiğini merak eden bir adam olacaksın.\n\n**Yol 2: 'Potansiyel' Geleceği**\nBu yolda, kaçınmacı doğanla yüzleşir ve Sorumluluk kasını sistematik olarak geliştirirsin. 5 yıl sonra, daha küçük ama karlı ve istikrarlı bir işin olabilir. Belki de nefret ettiğin idari görevleri dışarıdan birine devretmiş, en iyi yaptığın şeye odaklanmışsındır. Bağlanma yaralarını ele alarak, kendini savunmasız hissedecek kadar güvende olduğun, istikrarlı ve sevgi dolu bir ilişki içinde olabilirsin. Enerji seviyen daha yüksek olacak çünkü artık enerjini içsel çatışmalara ve kronik strese harcamıyorsun. Eylemlerin niyetlerinle aynı hizada olduğu için, kendini bütünleşmiş hissedeceksin.\n\n## Uygulanabilir İlerleme Yolu\nBunlar, seni Yol 2'ye taşıyacak somut, acımasızca pratik adımlardır.\n\n1.  **Kan kaybını durdur: Fiziksel temel.** Her gün, pazarlıksız, 20 dakikalık bir yürüyüşle başla. Bu spor değil, bedensel bir sıfırlamadır. Amaç, hareketsizliği kırmak ve bedenini "Savaş/Kaç" modundan çıkarmaktır.\n2.  **Sorumluluk açığını kapat:** İşin için bir görev yöneticisi uygulaması kullan (Todoist, Asana vb.). Her hedefi küçük, somut adımlara böl. Hedef "satışları artırmak" değil, "sabah 10'dan önce 5 takip e-postası göndermek" olmalı. Başarını sonuca göre değil, görevi tamamlamaya göre ölç.\n3.  **'Üretken Çatışma' pratiği yap:** Bir dahaki sefere bir arkadaşınla veya müşterinle küçük bir sorun yaşadığında, kaçmak yerine dur ve sakince kendi bakış açını ifade et. "Y olduğunda X hissediyorum" formülünü kullan. Amaç tartışmayı kazanmak değil, rahatsızlığa dayanabilmektir.\n4.  **Aşırı genellemeyi parçala:** "İşim batıyor" diye düşündüğünde, dur. Bu inancı destekleyen üç somut kanıt ve bu inancın *karşısında* olan üç somut kanıt yaz. Çarpıtmayla veriyle savaş.\n5.  **Bağlanma yarasını anla:** Amir Levine ve Rachel Heller'in "Bağlanma" (Attached) kitabını oku. Sadece kendi örüntünü anlamak bile iyileşmenin ilk ve en büyük adımıdır.\n6.  **İş rolünü yeniden tanımla:** Harika bir "tanıtımcı" ama kötü bir "yönetici" olduğunu kabul et. Biriyle ortaklık kurabilir misin? Kaçındığın görevler için otomasyon araçları kullanabilir misin? İşini zayıflıkların etrafında değil, güçlü yönlerin etrafında yeniden tasarla.\n7.  **Derinleşme zamanı planla:** Kaçındığın o anlatı soruları için, haftada bir gün sadece 15 dakika ayır ve sadece birine dürüstçe cevap yaz. Bunu, kaçınmayla yüzleşmek için bir egzersiz olarak gör.\n8.  **Somatik boşalma:** Omuzlarındaki gerginliği hissettiğinde, bilinçli olarak omuzlarını düşür, üç derin nefes al ve kollarını salla. Bedeninin tuttuğu stresi aktif olarak serbest bırak.\n\n## Kendi Sözlerinden: Anılar ve Anlam\nAnlatısal sorulara verdiğin cevaplar, nicel verilerden daha fazlasını ortaya koyuyor: bir savunma stratejisini.\n\nCevapların, kaçınmanın bir şaheseri: "boş ver", "istemiyorum", "no comment". Bu, hafıza eksikliği değil; bu, iç dünyanı korumak için inşa ettiğin bir duvar. Bu duvar seni koruyor gibi görünse de aslında seni kendi içinde hapsediyor.\n\nKritik bir anı sorulduğunda iki şey söylüyorsun: "çocukluğum ve Tayland tatilim". Bu büyüleyici bir eşleştirme. Biri, belirsiz, savunmasız ve potansiyel olarak acı dolu geniş bir dönem (çocukluk); diğeri ise belirli, egzotik bir kaçış anı. Bu, geçmişin çözülmemiş meselelerinden kaçma arzusuna dayalı bir temel yaşam anlatısını ima ediyor.\n\nDeğiştireceğin tek şey sorulduğunda, "boyumu uzatırdım" diyorsun. Bu, büyük olasılıkla bir metafordur. Dünyada "yeterli olmama", "ölçüyü tutturamama" hissine işaret ediyor. Bu "kısa kalma" hissi, muhtemelen başarısızlık korkunun ve gerçek zorluklardan kaçınmanın arkasındaki motordur.\n\nBu anlatısal desenler, verilerde gördüğümüz Korkulu-Kaçınmacı bağlanma stilini doğrudan besliyor. Bir şekilde yetersiz ("çok kısa") olduğun inancı, insanlar çok yaklaşırsa bu "kusuru" görecekleri ve seni reddedecekleri korkusunu yaratıyor. Bu yüzden onları güvende hissettiğin bir mesafede tutuyorsun. Ama o mesafede ne gerçek sevgi ne de gerçek başarı var.\n\n## Bulgular, Temeller ve Kanıtlar\nBu analiz, Myers-Briggs Tip Göstergesi (MBTI), Beş Faktör Modeli (Big Five), DISC profili, Bağlanma Teorisi ve Bilişsel Davranışçı Terapi gibi yerleşik psikolojik çerçevelerin bir sentezidir. Yorumlar, verdiğin nicel puanlar (örneğin, anket cevapların) ile nitel verilerin (örneğin, açık uçlu cevapların) entegrasyonuna dayanmaktadır.\n\nAmaç, farklı veri noktalarını birleştirerek kişiliğinin, davranışlarının ve zorluklarının altında yatan temel dinamikleri ortaya çıkaran tutarlı bir portre oluşturmaktır. Örneğin, Sorumluluk puanının düşüklüğü, belirttiğin "erteleme" alışkanlığı ve iş zorluklarınla doğrudan ilişkilendirilmiştir. Benzer şekilde, kaçınmacı bağlanma stilin, çatışma yönetimi tercihin ve anlatısal sorulardan kaçınman arasında güçlü bir bağlantı kurulmuştur.\n\nBu rapor, bir dizi olasılığı aydınlatır ancak geleceğini belirlemez. Senin tepkilerin, kararların ve eylemlerin, hangi geleceğin gerçekleşeceğini belirleyecektir. Bu, bir haritadır; yolculuk sana aittir.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilindirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	\N	0	2025-08-25 00:52:07.960348+03	2025-08-25 00:53:52.469463+03	{"language": "tr", "language_ok": true}	{"F1_AGE": "47", "F1_GENDER": "0", "F1_EDUCATION": "2", "F1_OCCUPATION": "online satış", "F1_FOCUS_AREAS": ["3", "6", "0"], "F1_YEARLY_GOAL": "ruh sağlığımın düzelmesi ve hayat enerjimin geri gelmesi", "F1_ENERGY_LEVEL": 5, "F1_RELATIONSHIP": "0", "F1_STRESS_LEVEL": 5, "F1_SLEEP_QUALITY": 6, "F1_BIGGEST_CHALLENGE": "işlerim iyi gitmiyor", "F1_LIFE_SATISFACTION": 3, "F1_PHYSICAL_ACTIVITY": "0"}	{"F2_VALUES": ["stimulation", "security", "power", "hedonism", "conformity", "benevolence", "universalism", "tradition", "self_direction", "achievement"], "F2_BIG5_01": 4, "F2_BIG5_02": 2, "F2_BIG5_03": 4, "F2_BIG5_04": 3, "F2_BIG5_05": 4, "F2_BIG5_06": 5, "F2_BIG5_07": 4, "F2_BIG5_08": 2, "F2_BIG5_09": 4, "F2_BIG5_10": 3, "F2_MBTI_01": "0", "F2_MBTI_02": "1", "F2_MBTI_03": "1", "F2_MBTI_04": "1", "F2_MBTI_05": "0", "F2_MBTI_06": "0", "F2_MBTI_07": "1", "F2_MBTI_08": "0", "F2_MBTI_09": "1", "F2_MBTI_10": "0", "F2_MBTI_11": "1", "F2_MBTI_12": "1", "F2_MBTI_13": "0", "F2_MBTI_14": "0", "F2_MBTI_15": "0", "F2_MBTI_16": "0", "F2_MBTI_17": "0", "F2_MBTI_18": "1", "F2_MBTI_19": "1", "F2_MBTI_20": "0"}	{"F3_FTP_01": 4, "F3_FTP_02": 3, "F3_FTP_03": 4, "F3_FTP_04": 4, "F3_DISC_01": {"most": "2", "least": "0"}, "F3_DISC_02": {"most": "3", "least": "0"}, "F3_DISC_03": {"most": "3", "least": "1"}, "F3_DISC_04": {"most": "0", "least": "2"}, "F3_DISC_05": {"most": "1", "least": "3"}, "F3_DISC_06": {"most": "1", "least": "2"}, "F3_DISC_07": {"most": "1", "least": "3"}, "F3_DISC_08": {"most": "1", "least": "2"}, "F3_DISC_09": {"most": "1", "least": "0"}, "F3_DISC_10": {"most": "0", "least": "2"}, "F3_DAILY_01": 8, "F3_DAILY_02": 6, "F3_DAILY_03": 3, "F3_DAILY_04": "olmadı bi şey", "F3_STORY_01": "çocukluğum ve tayland tatilim", "F3_STORY_02": "iyi bir dostsun", "F3_STORY_03": "boyumu uzatırdım", "F3_STORY_04": "boş ver", "F3_STORY_05": "istemiyorum", "F3_STORY_06": "çok var", "F3_STORY_07": "çokk var", "F3_STORY_08": "no comment", "F3_ATTACH_01": 4, "F3_ATTACH_02": 3, "F3_ATTACH_03": 4, "F3_ATTACH_04": 4, "F3_ATTACH_05": 4, "F3_ATTACH_06": 3, "F3_BELIEF_01": 3, "F3_BELIEF_02": 2, "F3_BELIEF_03": 4, "F3_BELIEF_04": 3, "F3_BELIEF_05": 4, "F3_BELIEF_06": 3, "S3_EMPATHY_1": 3, "S3_EMPATHY_2": 4, "S3_EMPATHY_3": 3, "S3_EMPATHY_4": 2, "S3_EMPATHY_5": 2, "S3_EMPATHY_6": 3, "F3_MEANING_01": 3, "F3_MEANING_02": 4, "F3_MEANING_03": 5, "F3_SOMATIC_01": "2", "F3_SOMATIC_02": ["2"], "S3_CONFLICT_1": [0], "S3_CONFLICT_2": [1], "F3_COG_DIST_01": ["2"], "S3_EMOTION_REG_1": 3, "S3_EMOTION_REG_2": 2, "S3_EMOTION_REG_3": 3, "S3_EMOTION_REG_4": 3, "S3_EMOTION_REG_5": 4, "S3_EMOTION_REG_6": 4, "F3_COPING_MECHANISMS": [0], "F3_SABOTAGE_PATTERNS": [1]}	[{"id": "block-0", "content": "Hazır mısın? Başlayalım..\\n\\nBu, verilerine dayanan stratejik bir analizdir. Amacımız seni iyi hissettirmek değil, daha güçlü ve etkili kılmaktır. Bazı kısımlar rahatsız edici olabilir; bu, değişimin başlangıcıdır. Şimdi, gerçeklerle yüzleşme zamanı.\\n\\n| Nitelik / Boyut | Puan |\\n|--------------------------------------|--------------------------------|\\n| **MBTI Tipi** | ESFJ |\\n| MBTI Dışadönüklük (E) | 80% |\\n| MBTI İçedönüklük (I) | 20% |\\n| MBTI Duyumsama (S) | 60% |\\n| MBTI Sezgi (N) | 40% |\\n| MBTI Düşünme (T) | 20% |\\n| MBTI Hissetme (F) | 80% |\\n| MBTI Yargılama (J) | 60% |\\n| MBTI Algılama (P) | 40% |\\n| **Big Five - Açıklık (O)** | 62.5% |\\n| **Big Five - Sorumluluk (C)** | 50% |\\n| **Big Five - Dışadönüklük (E)** | 75% |\\n| **Big Five - Uyumluluk (A)** | 62.5% |\\n| **Big Five - Nevrotiklik (N)** | 62.5% |\\n| **DISC - Baskınlık (D)** | 40% |\\n| **DISC - Etki (I)** | 70% |\\n| **DISC - Kararlılık (S)** | 35% |\\n| **DISC - Uygunluk (C)** | 50% |\\n| Bağlanma - Kaygı | 75% |\\n| Bağlanma - Kaçınma | 58.3% |\\n| Çatışma Stili (Birincil) | Kaçınmacı |\\n| Duygu Düzenleme - Yeniden Değerlendirme | 58.3% |\\n| Duygu Düzenleme - Bastırma | 50% |\\n| Empati - Duygusal İlgi | 41.7% |\\n| Empati - Perspektif Alma | 50% |\\n| Anlam ve Amaç Puanı | 75% |\\n| Gelecek Zaman Perspektifi Puanı | 68.8% |\\n| Baskın Bilişsel Çarpıtmalar | Aşırı Genelleme |\\n| Mevcut Somatik Durum | Savaş/Kaç |"}, {"id": "block-1", "content": "## Temel Kişiliğin\\nSenin temel yapın, insanlarla bağ kurmak ve onları etkilemek üzerine kurulu. **ESFJ** (Konsül) ve yüksek **Etki (I)** skorun, seni doğuştan sosyal, ikna edici ve başkalarının onayına değer veren biri yapıyor. Bu, \\"online satış\\" gibi bir alanda başarılı olmak için gereken ham maddeye sahip olduğun anlamına gelir: insanları kendine çekebilirsin. Ancak bu parlak yüzeyin altında, seni durduran ve enerjini tüketen ciddi çelişkiler var.\\n\\nEn büyük çelişki şu: Kişiliğin **Hissetme (F)** odaklı (%80) olmasına rağmen, gerçek empati becerin – başkalarının duygularını anlama ve onlarla rezonansa girme kapasiten – oldukça düşük (%41.7). Bu, bir \\"halk adamı\\" gibi görünürken, içten içe başkalarının duygusal yükünü taşıyacak enerjiden yoksun olduğun anlamına geliyor. İnsanlarla etkileşimlerin, seni beslemek yerine tüketiyor çünkü sıcakkanlılık rolünü oynuyorsun ama içsel kaynakların tükenmiş durumda.\\n\\nİkinci kritik sorun, %50'lik **Sorumluluk (Conscientiousness)** puanın. Bu, bir girişimci için ölümcül bir zayıflıktır. Fikirler üretebilir, insanları heyecanlandırabilirsin (yüksek Etki), ancak iş sıkıcı detaylara, takibe ve disiplinli çalışmaya geldiğinde bocalıyorsun. Bu, \\"işlerim iyi gitmiyor\\" demenin temel nedenidir. Stratejin var, ama siperlerde savaşacak askerin yok.\\n\\nYüksek **Nevrotiklik (%62.5)** ise bu ateşin üzerine benzin döküyor. Küçük başarısızlıkları felaketlere dönüştürüyor, kaygını körüklüyor ve zaten az olan yaşam enerjini emiyor. Bu, hayatının arka planında sürekli çalan bir alarm sireni gibi.\\n\\nTüm bunları birleştirdiğimizde ortaya çıkan arketip: **Tükenmiş Elçi**. Bir elçi gibi insanları bir araya getirme, etkileme ve bir davayı temsil etme potansiyeline sahipsin. Ancak krallığın (işin, ilişkilerin, iç dünyan) harabeye dönmüş durumda ve sen bu görevi yerine getirecek enerjiyi kaybetmişsin. Kendi potansiyelinden sürgün edilmiş bir elçisin."}, {"id": "block-2", "content": "## Güçlü Yönlerin\\n* **Sosyal Çekim Gücü:** Yüksek Dışadönüklük ve Etki skorların sayesinde insanları doğal olarak kendine çekersin. İkna kabiliyetin, doğru kullanıldığında en büyük sermayendir. Bu, satışın ve sosyal hayatın ön kapısını açan anahtardır.\\n* **Uyum Arayışı:** Yüksek Uyumluluk ve Hissetme odaklı yapın, çatışmadan kaçınmanı ve pozitif ilişkiler kurma arzunu gösterir. İnsanlar senin yanında genellikle rahat hisseder çünkü tehditkar değilsin.\\n* **İçsel Anlam Duygusu:** Mevcut zorluklarına rağmen, hayatın bir anlamı olduğuna dair inancın oldukça güçlü (%75). Bu, en karanlık zamanlarda bile tutunabileceğin bir çıpadır. Birçok insan bu çapadan yoksundur; bu senin gizli gücün.\\n* **Gelecek Odaklılık:** Geleceği planlama ve düşünme yeteneğin (%68.8) var. Bu, mevcut durumdan çıkmak için bir rota çizebileceğin anlamına gelir. Sorun rotayı çizmek değil, o yolda yürümektir."}, {"id": "block-3", "content": "## Kör Noktalar ve Riskler\\n* **Duygusal Uyumsuzluk (Yüksek Hissetme vs. Düşük Empati):** Bu senin Aşil topuğun. Dışarıya \\"duygusal\\" bir insan imajı çiziyorsun, ancak gerçek empati kapasiten tükenmiş durumda. Bu, ilişkilerini yüzeysel ve yorucu hale getiriyor. İnsanlar senin samimiyetini sorgulayabilir, sıcaklığının bir performans olduğunu hissedebilirler. Bunun bedeli, kalabalıklar içinde derin bir yalnızlıktır. Bu durumun temel nedeni, kendi içsel kaosunu yönetmekle o kadar meşgul olman ki başkalarına ayıracak duygusal alanın kalmamasıdır.\\n* **Sorumluluk Uçurumu (Hırs vs. Eylem):** Başarılı bir iş kurma arzun, tutarsız eylemlerinle doğrudan çelişiyor. %50'lik Sorumluluk puanın, bir girişimcinin envanterindeki en büyük yüktür. Bu bir karakter kusuru değil, ele alınmadığı takdirde başarısızlığı garanti eden stratejik bir darboğazdır. Belirttiğin \\"Erteleme\\" alışkanlığı bunun doğrudan bir sonucudur.\\n* **Bir Yaşam Stratejisi Olarak Kaçınma:** İster bir ilişkide, ister bu ankette olsun, rahatsız edici bir durumla karşılaştığındaki varsayılan tepkin geri çekilmek ve konuyu kapatmak. Cevaplarındaki \\"boş ver\\", \\"istemiyorum\\", \\"no comment\\" ifadeleri bunun kanıtıdır. Bu, felaket bir stratejidir. İşte, zorlu bir müşteriyi aramaktan kaçınmak anlamına gelir. İlişkilerde, partnerini duvarlarla karşılamak demektir. **Bunun bilinçdışı getirisi nedir?** Seni reddedilmekten ve başarısızlıktan korur. Tam olarak dahil olmadığın bir oyunda, asla tam olarak kaybedemezsin. Ama bunun bedeli, yarım yaşanmış bir hayat, yarım kurulmuş bir iş ve asla derinleşmeyen ilişkilerdir.\\n* **Fiziksel İhmal ve Bedensel Stres:** Bedenini, hayatının motoru olarak değil, stresinin bir deposu olarak kullanıyorsun. Sürekli \\"Savaş/Kaç\\" modunda olman ve omuzlarındaki/boynundaki ağrı, soyut kavramlar değil; bedeninin mevcut stratejinin sürdürülemez olduğuna dair çığlıklarıdır. \\"Hayat enerjini geri kazanma\\" hedefin, fiziksel durumunu ele almadan imkansızdır. Enerji, zihinsel bir illüzyon değildir; biyolojik bir gerçektir."}, {"id": "block-4", "content": "## İlişkiler ve Sosyal Dinamikler\\nİlişkilerdeki temel modelin, yüksek **Kaygılı (%75)** ve orta-yüksek **Kaçınmacı (%58.3)** bağlanma stilinle tanımlanıyor. Bu, \\"Korkulu-Kaçınmacı\\" bir örüntüdür. Yani, bir yandan yakınlık ve sevgiye derin bir özlem duyarken (kaygı), diğer yandan reddedilme ve incinme korkusuyla insanları kendinden uzak tutuyorsun (kaçınma).\\n\\nBu, bir \\"yaklaş-uzaklaş\\" dansına yol açar. Muhtemelen ilişkilere büyük bir hevesle başlarsın (Yüksek Dışadönüklük, Yüksek Etki), ancak işler ciddileşip duygusal risk arttığında duvarlarını örer ve geri çekilirsin. Birincil çatışma stilinin \\"Kaçınmacı\\" olması, sorunların konuşulmak yerine halının altına süpürülmesine neden olur. Bu, zamanla biriken bir zehirdir ve ilişkilerin sessizce ölmesine yol açar. 47 yaşında bekar olman, bu dinamiğin uzun vadeli bir sonucu olabilir."}, {"id": "block-5", "content": "## Kariyer ve Çalışma Tarzı\\nProfilin, satışın \\"ön cephesi\\" için mükemmel: ağ kurma, insanları etkileme, sunum yapma (Yüksek Etki, Yüksek Dışadönüklük). Ancak, işin \\"arka cephesi\\" için tamamen yetersiz: idari işler, detaylı takip, finansal yönetim, zorlu müşteri sorunlarını çözme (Düşük Sorumluluk, Düşük Kararlılık, Kaçınmacı Çatışma Stili).\\n\\nSen \\"fikir adamı\\"sın, \\"vitrin yüzü\\"sün. Ama \\"operasyon müdürü\\" veya \\"tahsilatçı\\" değilsin. Tek kişilik online satış işinde, bu rollerin hepsini üstlenmek zorundasın ve doğana aykırı olan kısımlarda başarısız oluyorsun. Bu sadece kişisel bir zayıflık değil, iş modelinde yapısal bir hatadır. Başarısızlık kaçınılmaz hale geliyor çünkü seni en çok zorlayan görevlerden kaçıyorsun."}, {"id": "block-6", "content": "## Duygusal Desenler ve Stres\\nYüksek Nevrotiklik, temel stres seviyeni belirliyor. Küçük bir aksilik, \\"Aşırı Genelleme\\" bilişsel çarpıtmanla birleşerek \\"bütün işim batıyor\\" gibi bir felaket senaryosuna dönüşüyor. Bu düşünce, bedenini anında \\"Savaş/Kaç\\" moduna sokuyor ve omuzlarındaki gerginlik artıyor.\\n\\nBu stresle başa çıkma yöntemin ise \\"Duygusal Yeme\\" ve \\"Kaçınma\\". Sorunla yüzleşmek yerine, yemek yiyerek veya sorunu görmezden gelerek anlık bir rahatlama arıyorsun. Bu, ölümcül bir geri bildirim döngüsü yaratır: Stres → Ye/Kaçın → İşler daha da kötüleşir → Daha fazla stres. Omuzlarındaki ağrı, bu kısır döngünün fiziksel kanıtıdır."}, {"id": "block-7", "content": "## Yaşam Örüntüleri ve Muhtemel Tuzaklar\\nHayatın muhtemelen, büyük bir hevesle başlanan (Yüksek Etki) ancak disiplinli takip eksikliği nedeniyle sönen projelerle doludur (Düşük Sorumluluk). İlişkilerde de benzer bir örüntü vardır: başlangıçta umut verici, ancak kaçınmacı doğan nedeniyle gerçek derinliğe ulaşamayan bağlar.\\n\\nGenel yaşam memnuniyetinin 10 üzerinden 3 olması, bu profilin doğal bir sonucudur. Doğal yeteneklerin (sosyal etki), kritik stratejik zayıflıkların (düşük sorumluluk, kaçınma) nedeniyle gerçek dünya başarısına dönüştürülemiyor. Potansiyelin ile gerçekliğin arasındaki bu uçurum, memnuniyetsizliğinin ve enerji kaybının ana kaynağıdır."}, {"id": "block-8", "content": "## Yol Ayrımı: İki Olası Gelecek\\nTüm bu analize dayanarak, önümüzdeki 5 yıl için iki gerçekçi senaryo çizelim.\\n\\n**Yol 1: 'Aynen Devam' Geleceği**\\nBu yolda, temel dinamiklerini değiştirmek için hiçbir şey yapmazsın. 5 yıl sonra, online işin ya tamamen batmış ya da kronik bir stres ve minimal gelir kaynağı olmaya devam ediyor olacak. Bekar kalmaya veya bir dizi yüzeysel ilişki döngüsüne devam edeceksin. Hareketsiz yaşam tarzı ve kronik stres nedeniyle fiziksel sağlığın bozulmuş olacak. Aradığın \\"yaşam enerjisi\\", hayal kırıklığı ve teslimiyet katmanlarının altına daha da gömülmüş olacak. 52 yaşında, yaşından daha yaşlı hisseden ve potansiyelinin nereye gittiğini merak eden bir adam olacaksın.\\n\\n**Yol 2: 'Potansiyel' Geleceği**\\nBu yolda, kaçınmacı doğanla yüzleşir ve Sorumluluk kasını sistematik olarak geliştirirsin. 5 yıl sonra, daha küçük ama karlı ve istikrarlı bir işin olabilir. Belki de nefret ettiğin idari görevleri dışarıdan birine devretmiş, en iyi yaptığın şeye odaklanmışsındır. Bağlanma yaralarını ele alarak, kendini savunmasız hissedecek kadar güvende olduğun, istikrarlı ve sevgi dolu bir ilişki içinde olabilirsin. Enerji seviyen daha yüksek olacak çünkü artık enerjini içsel çatışmalara ve kronik strese harcamıyorsun. Eylemlerin niyetlerinle aynı hizada olduğu için, kendini bütünleşmiş hissedeceksin."}, {"id": "block-9", "content": "## Uygulanabilir İlerleme Yolu\\nBunlar, seni Yol 2'ye taşıyacak somut, acımasızca pratik adımlardır.\\n\\n1.  **Kan kaybını durdur: Fiziksel temel.** Her gün, pazarlıksız, 20 dakikalık bir yürüyüşle başla. Bu spor değil, bedensel bir sıfırlamadır. Amaç, hareketsizliği kırmak ve bedenini \\"Savaş/Kaç\\" modundan çıkarmaktır.\\n2.  **Sorumluluk açığını kapat:** İşin için bir görev yöneticisi uygulaması kullan (Todoist, Asana vb.). Her hedefi küçük, somut adımlara böl. Hedef \\"satışları artırmak\\" değil, \\"sabah 10'dan önce 5 takip e-postası göndermek\\" olmalı. Başarını sonuca göre değil, görevi tamamlamaya göre ölç.\\n3.  **'Üretken Çatışma' pratiği yap:** Bir dahaki sefere bir arkadaşınla veya müşterinle küçük bir sorun yaşadığında, kaçmak yerine dur ve sakince kendi bakış açını ifade et. \\"Y olduğunda X hissediyorum\\" formülünü kullan. Amaç tartışmayı kazanmak değil, rahatsızlığa dayanabilmektir.\\n4.  **Aşırı genellemeyi parçala:** \\"İşim batıyor\\" diye düşündüğünde, dur. Bu inancı destekleyen üç somut kanıt ve bu inancın *karşısında* olan üç somut kanıt yaz. Çarpıtmayla veriyle savaş.\\n5.  **Bağlanma yarasını anla:** Amir Levine ve Rachel Heller'in \\"Bağlanma\\" (Attached) kitabını oku. Sadece kendi örüntünü anlamak bile iyileşmenin ilk ve en büyük adımıdır.\\n6.  **İş rolünü yeniden tanımla:** Harika bir \\"tanıtımcı\\" ama kötü bir \\"yönetici\\" olduğunu kabul et. Biriyle ortaklık kurabilir misin? Kaçındığın görevler için otomasyon araçları kullanabilir misin? İşini zayıflıkların etrafında değil, güçlü yönlerin etrafında yeniden tasarla.\\n7.  **Derinleşme zamanı planla:** Kaçındığın o anlatı soruları için, haftada bir gün sadece 15 dakika ayır ve sadece birine dürüstçe cevap yaz. Bunu, kaçınmayla yüzleşmek için bir egzersiz olarak gör.\\n8.  **Somatik boşalma:** Omuzlarındaki gerginliği hissettiğinde, bilinçli olarak omuzlarını düşür, üç derin nefes al ve kollarını salla. Bedeninin tuttuğu stresi aktif olarak serbest bırak."}, {"id": "block-10", "content": "## Kendi Sözlerinden: Anılar ve Anlam\\nAnlatısal sorulara verdiğin cevaplar, nicel verilerden daha fazlasını ortaya koyuyor: bir savunma stratejisini.\\n\\nCevapların, kaçınmanın bir şaheseri: \\"boş ver\\", \\"istemiyorum\\", \\"no comment\\". Bu, hafıza eksikliği değil; bu, iç dünyanı korumak için inşa ettiğin bir duvar. Bu duvar seni koruyor gibi görünse de aslında seni kendi içinde hapsediyor.\\n\\nKritik bir anı sorulduğunda iki şey söylüyorsun: \\"çocukluğum ve Tayland tatilim\\". Bu büyüleyici bir eşleştirme. Biri, belirsiz, savunmasız ve potansiyel olarak acı dolu geniş bir dönem (çocukluk); diğeri ise belirli, egzotik bir kaçış anı. Bu, geçmişin çözülmemiş meselelerinden kaçma arzusuna dayalı bir temel yaşam anlatısını ima ediyor.\\n\\nDeğiştireceğin tek şey sorulduğunda, \\"boyumu uzatırdım\\" diyorsun. Bu, büyük olasılıkla bir metafordur. Dünyada \\"yeterli olmama\\", \\"ölçüyü tutturamama\\" hissine işaret ediyor. Bu \\"kısa kalma\\" hissi, muhtemelen başarısızlık korkunun ve gerçek zorluklardan kaçınmanın arkasındaki motordur.\\n\\nBu anlatısal desenler, verilerde gördüğümüz Korkulu-Kaçınmacı bağlanma stilini doğrudan besliyor. Bir şekilde yetersiz (\\"çok kısa\\") olduğun inancı, insanlar çok yaklaşırsa bu \\"kusuru\\" görecekleri ve seni reddedecekleri korkusunu yaratıyor. Bu yüzden onları güvende hissettiğin bir mesafede tutuyorsun. Ama o mesafede ne gerçek sevgi ne de gerçek başarı var."}, {"id": "block-11", "content": "## Bulgular, Temeller ve Kanıtlar\\nBu analiz, Myers-Briggs Tip Göstergesi (MBTI), Beş Faktör Modeli (Big Five), DISC profili, Bağlanma Teorisi ve Bilişsel Davranışçı Terapi gibi yerleşik psikolojik çerçevelerin bir sentezidir. Yorumlar, verdiğin nicel puanlar (örneğin, anket cevapların) ile nitel verilerin (örneğin, açık uçlu cevapların) entegrasyonuna dayanmaktadır.\\n\\nAmaç, farklı veri noktalarını birleştirerek kişiliğinin, davranışlarının ve zorluklarının altında yatan temel dinamikleri ortaya çıkaran tutarlı bir portre oluşturmaktır. Örneğin, Sorumluluk puanının düşüklüğü, belirttiğin \\"erteleme\\" alışkanlığı ve iş zorluklarınla doğrudan ilişkilendirilmiştir. Benzer şekilde, kaçınmacı bağlanma stilin, çatışma yönetimi tercihin ve anlatısal sorulardan kaçınman arasında güçlü bir bağlantı kurulmuştur.\\n\\nBu rapor, bir dizi olasılığı aydınlatır ancak geleceğini belirlemez. Senin tepkilerin, kararların ve eylemlerin, hangi geleceğin gerçekleşeceğini belirleyecektir. Bu, bir haritadır; yolculuk sana aittir."}, {"id": "block-12", "content": "## Yasal Uyarı\\n\\nBu rapor yalnızca kişisel gelişim ve bilgilindirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır."}]	2025-08-29 20:45:13.649121
428c08ce-b519-4a58-8795-c78fbf691123	ebe6eee2-01ae-4753-9737-0983b0330880	self	completed	\N	\N	*Bu rapor 29 Ağustos 2025 22:20 tarihinde oluşturulmuştur.*\n\n---\n\nHazır mısın? Hadi başlayalım..\n\nBu rapor, kendini kandırmanın bittiği yerdir. Amacım sana iyi hissettirmek değil, seni gerçeklerle yüzleştirerek daha güçlü ve etkili kılmak. Dünya bir terapi odası değil, bir rekabet arenası. Zayıflıkların, başkaları veya koşullar tarafından istismar edilecek stratejik dezavantajlardır. Şimdi, zırhını kuşan ve gerçeklerle yüzleşmeye hazırlan. Çünkü potansiyelini israf etmeye devam etmeni izlemeyeceğim.\n\n| Özellik / Boyut | Puan |\n|----------------------------------|----------------------------------------------------------|\n| **MBTI Tipi** | ISTP |\n| MBTI Dışadönüklük (E) | 40% |\n| MBTI İçedönüklük (I) | 60% |\n| MBTI Duyumsama (S) | 60% |\n| MBTI Sezgi (N) | 40% |\n| MBTI Düşünme (T) | 80% |\n| MBTI Hissetme (F) | 20% |\n| MBTI Yargılama (J) | 40% |\n| MBTI Algılama (P) | 60% |\n| **Big Five - Deneyime Açıklık (O)** | 50% |\n| **Big Five - Sorumluluk (C)** | 13% |\n| **Big Five - Dışadönüklük (E)** | 50% |\n| **Big Five - Uyumluluk (A)** | 50% |\n| **Big Five - Nevrotiklik (N)** | 75% |\n| **DISC - Baskınlık (D)** | 70% |\n| **DISC - Etkileyicilik (I)** | 10% |\n| **DISC - Sadakat (S)** | 10% |\n| **DISC - Uygunluk (C)** | 10% |\n| Bağlanma - Kaygı | 75% |\n| Bağlanma - Kaçınma | 75% |\n| Çatışma Stili (Birincil) | Durumsal (Rekabetçi/İşbirlikçi) |\n| Duygu Düzenleme - Yeniden Değerlendirme| 42% |\n| Duygu Düzenleme - Bastırma | 25% |\n| Empati - Duygusal İlgi | 50% |\n| Empati - Perspektif Alma | 67% |\n| Anlam ve Amaç Puanı | 67% |\n| Gelecek Zaman Perspektifi Puanı | 81% |\n| Baskın Bilişsel Çarpıtmalar | Felaketleştirme, Aşırı Genelleme, -meli, -malı Cümleleri |\n| Mevcut Bedensel Durum | Kapanma ve Donma |\n\n## Temel Kişiliğiniz\n\nProfilin, son derece nadir ve içsel olarak çelişkili bir yapıyı ortaya koyuyor. Kağıt üzerinde, bir **ISTP**'sin: mantıklı, pragmatik, problem çözmeye odaklı bir "Usta". Aynı zamanda, DISC profilindeki ezici **Baskınlık (D)**, kontrolü ele alma, sonuç elde etme ve yönetme arzusunu haykırıyor. Bu kombinasyon, normal şartlarda durdurulamaz bir teknoloji girişimcisi, bir mucit veya bir stratejist yaratırdı. Ancak senin durumunda, bu güçlü motor, iki kritik arıza nedeniyle boşa çalışıyor: **Aşırı Yüksek Nevrotiklik (%75)** ve **Tehlikeli Düzeyde Düşük Sorumluluk (%13)**.\n\nBu, yüksek performanslı bir yarış arabasına sahip olup, lastiklerinin patlak ve yakıt deposunun delik olması gibidir. Zekan ve vizyonun var; büyük resmi görebiliyor ve geleceğe dair güçlü bir umut taşıyorsun (Gelecek Perspektifi: %81). Ancak duygusal fırtınalar (Nevrotiklik) seni sürekli yoldan çıkarıyor ve temel disiplin eksikliği (Sorumluluk) aracın ilerlemesini engelliyor. Sonuç, sürekli bir "neredeyse başardım" döngüsü, hayal kırıklığı ve boşa harcanan muazzam bir potansiyel.\n\nSen, zihninin ve geçmişinin hapishanesine kapatılmış bir stratejistsin. Dışarıdaki krallığı fethetmek için tüm planlara sahipsin ama kendi iç kaleni savunmaktan acizsin. Bu yüzden, seni tanımlayan arketip **"Kafesteki Stratejist"**tir. Zekan keskin, hırsın gerçek ama seni felç eden görünmez parmaklıklar var: İşlenmemiş travma, yerleşmiş disiplinsizlik ve derin bir terk edilme korkusu.\n\n## Güçlü Yönleriniz\n\nZayıflıklarına odaklanmadan önce, hangi silahlara sahip olduğunu netleştirelim. Bunlar, doğru kullanıldığında seni ileriye taşıyacak araçlardır.\n\n*   **Analitik ve Stratejik Zeka:** Senaryoları analiz etme, mantıksal bağlantılar kurma ve karmaşık sorunlara çözüm bulma konusunda doğal bir yeteneğin var. Düşünme (T) puanının %80 olması, kararlarını duygusal dalgalanmalardan (eğer yönetebilirsen) arındırıp objektif kriterlere dayandırabildiğini gösteriyor. Tartışmalarda zekanı kullanma şeklinden insanların etkilenmesi boşuna değil.\n\n*   **Vizyoner Gelecek Odaklılığı:** %81 gibi yüksek bir Gelecek Zaman Perspektifi puanı, bugünkü eylemlerinin yarını nasıl şekillendirdiğini derinden anladığını gösteriyor. Bu, uzun vadeli hedefler belirlemeni ve bu hedeflere ilhamla bağlanmanı sağlar. Büyük bir teknoloji şirketi kurma hayalin, bu vizyoner gücün bir kanıtıdır.\n\n*   **Girişimci Cesareti ve Risk Alma:** Yüksek Baskınlık (D) profilin ve kendi anlatımın, başkalarının çekindiği yerlerde adım atmaktan korkmadığını gösteriyor. Belirsizliğe toleransın ve kontrolü ele alma içgüdün, bir girişimci için temel yakıttır.\n\n*   **Bilişsel Empati (Perspektif Alma):** Duygusal olarak empati kurmakta zorlansan da (%50 Duygusal İlgi), bir durumu başkasının gözünden görme ve argümanlarını anlama yeteneğin (%67 Perspektif Alma) oldukça gelişmiş. Bu, müzakere ve strateji gerektiren durumlarda sana avantaj sağlar.\n\n## Kör Noktalar ve Riskler\n\nBurası acı gerçeklerin başladığı yer. Bunlar küçük kusurlar değil, seni tekrar tekrar başarısızlığa uğratan, seni öngörülebilir ve savunmasız kılan sistemik zayıflıklardır.\n\n### 1. Felç Eden Disiplinsizlik\n\n*   **Desen:** Sorumluluk (Conscientiousness) puanın %13. Bu istatistiksel bir anormallik değil, bir alarm sireni. Planlama, organize olma, detaylara dikkat etme ve en önemlisi, bir işi sonuna kadar götürme konusunda kronik bir yetersizlik içindesin. Erteleme, senin için bir alışkanlık değil, bir yaşam biçimi.\n*   **Maliyet:** Bu, büyük hedeflerinin önündeki en büyük engel. Tech startup'lar fikirlerle değil, amansız ve sıkıcı bir uygulama ile inşa edilir. Bu özellik, finansal istikrarsızlığa, yarım kalmış projelere ve en sonunda kendine olan saygını yitirmene neden olur. "Ticaret yerine kariyer seçmeliydim" pişmanlığın, bu içsel gerçeği fark etmenin bir yansımasıdır; dış bir yapının seni disipline sokacağını umuyordun.\n*   **Altta Yatan Sebep ve Bilinçdışı Kazanç:** Bu tembellik değil, bir savunma mekanizması. **Bilinçdışı Kazancın**, egonu korumaktır. Eğer bir işe "gerçekten" tüm gücünle asılmazsan ve başarısız olursan, her zaman "isteseydim yapardım" bahanesine sığınabilirsin. Bu, tüm potansiyelini ortaya koyup yine de yetersiz kalma korkusundan seni koruyan bir kalkandır.\n\n### 2. Gücün Karanlık Yüzü\n\n*   **Desen:** Yüksek Baskınlık (D) ve "en çok gurur duyduğun anı" olarak anlattığın hikaye, tehlikeli bir dinamiği ortaya koyuyor. Bir kadını soğukkanlı bir manipülasyonla kürtaja zorladığın anı, "olman gereken adam" olarak idealize ediyorsun. Bu, gücü, kontrolü ve başkaları üzerinde tahakküm kurmayı, zayıflığa karşı nihai panzehir olarak gördüğünü gösteriyor.\n*   **Maliyet:** Bu zihniyet, gerçek ve sürdürülebilir başarıyı sabote eder. Güven üzerine kurulu ortaklıklar kurmanı, yetenekli insanları kendine çekmeni ve sağlıklı ilişkiler yaşamanı imkansız hale getirir. Bu "alfa" persona, yalnız bir kral yaratır; etrafında korkuyla itaat edenler olur ama asla sadakatle bağlı olanlar olmaz.\n*   **Altta Yatan Sebep ve Bilinçdışı Kazanç:** Bu, babandan gördüğün fiziksel ve psikolojik şiddete ve çocukluğundaki mutlak çaresizliğe karşı geliştirilmiş travmatik bir tepkidir. Asla bir daha o kadar güçsüz hissetmemek için, gücün en acımasız ve kontrolcü biçimine sığınıyorsun. **Bilinçdışı Kazancın:** Bu soğuk ve umursamaz tavır, seni o çaresiz, korkmuş çocuk olmanın dehşetinden koruyan bir zırhtır.\n\n### 3. Korku Temelli Bağlanma\n\n*   **Desen:** %75 Kaygı ve %75 Kaçınma. Bu, "Korkulu-Kaçınmacı" bağlanma stilidir. Hem yakınlığa ve onaya umutsuzca ihtiyaç duyuyorsun (Kaygı) hem de biri sana çok yaklaştığında kendini tehdit altında hissedip onu itiyorsun (Kaçınma). "İyi anlaşabildiğim bir kız arkadaşımın olması" hedefinle bu desen doğrudan çelişir.\n*   **Maliyet:** Yalnızlık, istikrarsız ve dramatik ilişkiler, ve "kaçıp sığınabileceğim kadar beni önemseyecek hiç kimse yok hayatımda" hissinin kendini gerçekleştiren bir kehanete dönüşmesi. İlişkileri, onlar seni terk etmeden önce senin sabote etmenle sonuçlanır.\n*   **Altta Yatan Sebep:** Çocukluktaki istismar ve ihmal. Temel inancın, sevilmeye layık olmadığın ("kusurlu ve sevilmeye layık olmadığıma inanırım" - 5/5) ve eninde sonunda terk edileceğin ("insanların eninde sonunda beni hayal kırıklığına uğratacağına... inanırım" - 4/5).\n\n## İlişkiler ve Sosyal Dinamikler\n\nİlişkilerdeki temel dinamiğin bir "itme-çekme" oyunudur. Birini istersin, onu elde etmek için zekanı ve karizmanı kullanırsın. Ancak yakınlık arttıkça, içindeki alarm zilleri çalmaya başlar. Terk edilme korkun (Kaygı) tavan yapar. Bu korkuyla başa çıkmak için, kontrolü ele almak adına uzaklaşır, duvarlar örer veya partnerini itersin (Kaçınma). Bu döngü, partnerin için kafa karıştırıcı ve yorucudur ve genellikle ilişkinin sonunu getirir.\n\nDuygularını etkili bir şekilde ne yeniden değerlendirebiliyor (%42) ne de bastırabiliyorsun (%25). Bu, duygularının ham ve yoğun bir şekilde ortaya çıktığı anlamına gelir. Bu durum, Yüksek Nevrotikliğinle birleştiğinde, ilişkilerde küçük anlaşmazlıkları büyük krizlere dönüştürme potansiyeline sahip.\n\n## Kariyer ve Çalışma Tarzı\n\nKariyerindeki temel çelişki şudur: Bir imparatorluk kurmak isteyen bir lidersin (Yüksek D) ama bir imparatorluğu ayakta tutan günlük, sıkıcı işlerden nefret eden bir askersin (Düşük C). Sen bir "fikir adamısın". Başlangıç enerjin yüksek, vizyonun parlak. Ancak uygulama, takip, bürokrasi ve rutin gerektiren her şey senin için bir eziyet.\n\nBu yüzden evden, tek başına çalışmak senin için hem bir sığınak hem de bir tuzak. Sığınak, çünkü kimseye hesap vermek zorunda değilsin. Tuzak, çünkü seni disipline edecek ve sorumlu tutacak hiçbir dış yapı yok. Başarın, Düşük Sorumluluğunu telafi edecek sistemler kurmana veya bu açığı kapatacak ortaklar bulmana bağlı. Aksi takdirde, parlak fikirlerle dolu bir mezarlık inşa etmeye devam edersin.\n\n## Duygusal Desenler ve Stres\n\nStres seviyen 7/10, hayat memnuniyetin ise 3/10. Bu rakamlar, iç dünyanda bir savaş olduğunu gösteriyor. Yüksek Nevrotikliğin, küçük tetikleyicileri büyük tehditler olarak algılamana neden oluyor. Başka birinin başarısını duyduğunda ("yeni yapay zeka milyarderleri") hissettiğin yoğun "içerleme" ve "kıskançlık", kendi yetersizlik duygularının ne kadar yüzeye yakın olduğunun bir kanıtı.\n\nBedenin bu stresi taşıyor. Midendeki düğüm, sıktığın çene ve kalp çarpıntıların, sinir sisteminin sürekli "Savaş ya da Kaç" modunda olduğunun fiziksel işaretleri. Ancak mevcut durumun daha da endişe verici: "Kapanma ve Donma". Bu, sinir sisteminin tehditle başa çıkamadığı ve pes ettiği noktadır. Uyuşukluk, içe kapanma ve boşluk hissi... Bu, çocukluktaki çaresizliğin bedensel bir yankısıdır. Hareketsiz yaşam tarzın bu durumu daha da kötüleştiriyor.\n\n## Hayat Kalıpları ve Muhtemel Tuzaklar\n\nHayatındaki ana kalıp, "parlama ve sönme" döngüsüdür. Büyük bir hevesle yeni bir projeye başlarsın, ilk engelleri zekanla aşarsın, ancak uzun vadeli sebat ve sıkıcı detaylar gerektiğinde enerjin tükenir ve proje ölür. Sonra kendini suçlar, hayal kırıklığına uğrar ve bir sonraki "kurtarıcı" fikri beklersin.\n\nEn büyük tuzağın, problemin "dışarıda" olduğuna inanmaktır. Eğer doğru fikir, doğru ortak, doğru şehir veya doğru kadın gelirse her şeyin düzeleceğini düşünüyorsun. Ama sorun bu değil. Sorun, işletim sisteminin kendisinde. Yeni bir yazılım yüklemeye çalışıyorsun ama donanım (duygusal düzenleme ve disiplin becerilerin) çökmüş durumda.\n\n## Yol Ayrımı: İki Muhtemel Gelecek\n\nBugün durduğun yerden, önümüzdeki 5 yıl için iki net yol görünüyor. Seçim senin.\n\n### Patika 1: 'Aynı Kalan' Gelecek\n\nEğer hiçbir şeyi temelden değiştirmezsen, 5 yıl sonra 52 yaşında olacaksın. Muhtemelen birkaç "neredeyse oluyordu" teknoloji girişimi hikayen daha olacak. Hâlâ "bir sonraki büyük fikrin" peşinde koşuyor olacaksın. Finansal durumun istikrarsız, stres seviyen kronik olarak yüksek olacak. "İyi anlaşabildiğin bir kız arkadaş" hayalin, birkaç başarısız ve dramatik denemeden sonra daha da uzaklaşmış olacak. İçindeki o parlak stratejist, pişmanlık ve "eğer yapsaydım"larla dolu bir kafeste, giderek daha öfkeli ve umutsuz bir hale gelecek. Çocukluğunun çaresizliği, yetişkinliğinin acı gerçeğine dönüşecek.\n\n### Patika 2: 'Potansiyel' Gelecek\n\nEğer bu raporu bir hakaret olarak değil, bir savaş çağrısı olarak kabul edersen, her şey değişebilir. Önümüzdeki 1-2 yılı, yeni bir iş kurmaya değil, kendini yeniden inşa etmeye adarsın. Travmalarınla yüzleşmek için profesyonel yardım alırsın. Disiplini bir ilham anı olarak değil, her gün yapılan sıkıcı bir kas antrenmanı olarak görmeye başlarsın. Fiziksel olarak güçlenirsin. 5 yıl sonra, 52 yaşında, belki daha küçük ama istikrarlı ve kârlı bir işin başında olursun. Çünkü bir fikri başlatmanın değil, bir işi sürdürmenin ne demek olduğunu öğrenmişsindir. Duygusal olarak daha dengeli, daha az reaktif bir adam olursun. Ve bu istikrar, hayatına gerçekten sağlıklı ve destekleyici bir ilişki çekmeni sağlar. Kafesteki stratejist sonunda özgür kalır, çünkü savaşması gereken krallığın dışarıda değil, içeride olduğunu anlamıştır.\n\n## Uygulanabilir İleriye Dönük Yol Haritası\n\nBunlar iyi niyetli tavsiyeler değil, emirlerdir. Potansiyelini israf etmeyi bırakmak istiyorsan, bunları yapacaksın.\n\n1.  **Profesyonel Yardım Al (Pazarlıksız):** Kendi başına çözemeyeceğin derin travmaların var. Babandan gördüğün şiddet, terk edilme şemaların ve çarpık güç algın, bir terapistle, özellikle EMDR veya şema terapi gibi yöntemlerle çalışılmalıdır. Bu bir seçenek değil, bir zorunluluk.\n\n2.  **Sorumluluğu Kas Gibi Çalıştır:** Disiplin, ilhamla gelmez. Tekrarla gelir. Her gün, yatağını toplamak gibi küçücük bir şeyle başla. Ardından, 15 dakika boyunca kesintisiz çalış. Sadece 15 dakika. Bunu bir ay boyunca her gün yap. Amacın bir startup kurmak değil, "sözünü tutma" kasını geliştirmek.\n\n3.  **Disiplini Dışsallaştır:** Madem içinde yok, dışarıdan al. Bir iş koçu tut. Seni her hafta arayıp hesap soracak bir arkadaşınla anlaş. Trello, Asana gibi proje yönetim araçlarını kullan ve görevlerini en küçük adımlara böl. Kendi iradene güvenmeyi bırak, sistemlere güven.\n\n4.  **Bedenini Harekete Geçir:** "Kapanma" durumundan çıkmanın en hızlı yolu bedeni hareket ettirmektir. Haftada 3 gün ağırlık antrenmanı yapmaya başla. Bu, sadece fiziksel görünümün için değil (ki bu senin için önemli), aynı zamanda sinir sistemini yeniden düzenlemek, stresi azaltmak ve kendine olan güvenini inşa etmek için kritiktir.\n\n5.  **"Güç" Tanımını Yeniden Yaz:** Gurur duyduğun o anıyı bir kenara bırak. Gerçek güç, başkalarını manipüle etmek değil, kendi içindeki kaosu yönetebilmektir. Gerçek alfa, duygularından kaçan değil, onlarla yüzleşip onları yönetebilen adamdır. Bu yeni tanımı benimse.\n\n6.  **Duygu Düzenleme Pratiği Yap:** Günde 5 dakika. Sadece otur ve nefesini izle. Zihnine gelen düşünceleri ve duyguları yargılamadan gözlemle. Bu, reaktif olmak yerine yanıt vermeyi öğrenmenin ilk adımıdır. Stres anında, midendeki düğüme veya çenendeki gerginliğe odaklan. Sadece fark et. Bu, bedeninle yeniden bağlantı kurmanı sağlayacak.\n\n7.  **Okumayı ve Öğrenmeyi Stratejikleştir:** Bilgili olman bir güç. Ancak bunu yapılandır. "Attachment Theory" (Bağlanma Kuramı), "Cognitive Behavioral Therapy" (Bilişsel Davranışçı Terapi) ve "Atomic Habits" (Atomik Alışkanlıklar) gibi konuları oku. Problemlerini entelektüel olarak anlamak, çözüm için motivasyonunu artıracaktır.\n\n8.  **Düşük Riskli Sosyal Arenalara Gir:** Bir hobi kursuna yazıl. Bir spor takımına katıl. Amacın bir kız arkadaş bulmak değil. Amacın, insanlarla beklentisiz, düşük basınçlı ortamlarda etkileşim kurma alıştırması yapmak. Bu, bağlanma korkularını yavaş yavaş desensitize etmene yardımcı olur.\n\n## Kendi Sözlerinizden: Anılar ve Anlam\n\nHikayelerin, kim olduğunun ham verileridir. Seninkiler, birbiriyle savaşan iki temel temayı ortaya koyuyor: **Özgürlük/Kurtuluş** ve **Kapana Kısılma/Çaresizlik**.\n\nMutlu anıların – askerliğin bitişi, arkadaşlarla evden kaçışlar, kedilerine kavuşman – hepsi bir tür esaretten kurtuluş anlarıdır. Bu, hayatındaki en derin arzunun **özgürlük** olduğunu gösteriyor. En kötü anıların ise tam tersi: Babanın şiddetinden kaçamayan beş parasız bir çocuk, yoksulluğun içinde kapana kısılmış bir genç. Bu deneyimler, "Terk Edilme" ve "Kusurluluk" şemalarını ruhuna kazımış. "Kaçıp sığınabileceğim... hiç kimse yoktu hayatımda. hala daha yok" cümlen, bu yaranın ne kadar taze ve derin olduğunun kanıtıdır.\n\nEn çok gurur duyduğun anı, bu dinamiğin en net resmidir. İstenmeyen bir hamilelik durumunda kendini "kapana kısılmış" hissettin. Verdiğin tepki, çocuklukta sana yapılanın aynısını başkasına yapmaktı: Soğuk, kontrolcü ve acımasız bir güç gösterisiyle kendini durumdan "kurtarmak". Bu, senin için bir zafer anıydı çünkü o an için, kurban değil, fail sendin. Bu, travmanın kendini nasıl tekrar ettiğinin trajik bir örneğidir.\n\nHayat hikayen, psikolojide "Kirlenme Anlatısı" (Contamination Narrative) dediğimiz şeye uyuyor: iyi bir başlangıç (zekan, potansiyelin) kötü bir olayla (travma, disiplinsizlik) "kirlenir" ve olumsuz bir sonuca yol açar. Senin görevin, bu anlatıyı yeniden yazmaktır. Kurtuluşun, başkalarını kontrol etmekte değil, kendi içindeki o çaresiz çocuğu iyileştirmekte ve ona bugün ihtiyaç duyduğu güvenliği ve yapıyı sağlamaktadır. Anlam ve Amaç puanının (%67) orta düzeyde olması, bir misyonun olduğunu hissettiğini ama mevcut hayatının bu misyonu yansıtmadığını gösteriyor. Anlam, bu iki ucu birleştirdiğinde bulunacaktır.\n\n## Bulgular, Temeller ve Kanıtlar\n\nBu analiz, sağladığın yanıtlara dayanarak oluşturulmuş bütünsel bir portredir. Kişiliğinin temel yapısını anlamak için Myers-Briggs Tip Göstergesi (MBTI), Beş Faktör Kişilik Modeli (Big Five) ve DISC gibi köklü psikometrik araçlardan yararlanılmıştır. Bu temel yapı üzerine, ilişkilerdeki derin kalıplarını ortaya çıkarmak için Bağlanma Kuramı ve Şema Terapi prensipleri entegre edilmiştir.\n\nDuygusal ve bilişsel alışkanlıkların, Duygu Düzenleme, Empati ve Bilişsel Çarpıtmalar üzerine yapılan araştırmalarla değerlendirilmiştir. Geleceğe bakış açın ve hayattaki anlam arayışın, sırasıyla Gelecek Zaman Perspektifi ve Logoterapi (Anlam Terapisi) çerçevelerinde incelenmiştir. Son olarak, kişisel anlatıların ve anıların, kimliğini ve temel motivasyonlarını şekillendiren yaşam öyküsü temalarını belirlemek için analiz edilmiştir.\n\nBu çok katmanlı yaklaşım, sadece yüzeysel davranışlarını değil, aynı zamanda bu davranışların altında yatan derin inançları, duygusal sürücüleri ve bilinçdışı kalıpları da aydınlatmayı amaçlamaktadır. Sonuçlar, bir "etiketleme" aracı değil, kendini anlaman ve stratejik olarak geliştirmen için tasarlanmış bir yol haritasıdır.\n\n## Yasal Uyarı\n\nBu rapor yalnızca kişisel gelişim ve bilgilindirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır.	\N	Analysis timed out after 8 minutes	0	2025-08-29 22:10:43+03	2025-08-29 22:20:44.861754+03	{"language": "tr", "is_update": true, "language_ok": true, "generated_at": "2025-08-29T19:20:44.861Z"}	{"F1_AGE": "47", "F1_GENDER": "0", "F1_EDUCATION": "2", "F1_OCCUPATION": "girişimciyim. kendi işimi yapıyorum ama evden çalışıyorum. online ticaret ama bir tech startup gerçekleştirmek için uğraşıyorum", "F1_FOCUS_AREAS": ["6", "0", "2"], "F1_YEARLY_GOAL": "üzerinde çalıştıım bir kaç tech startup ımın başarılı olmuş olması ve ilerisi için de büyüme potansiyeli göstermesi. iyi anlaşabildiğim bir kız arkaaşımın olması\\n", "F1_ENERGY_LEVEL": 6, "F1_RELATIONSHIP": "0", "F1_STRESS_LEVEL": 7, "F1_SLEEP_QUALITY": 7, "F1_BIGGEST_CHALLENGE": "ruhsal sağlığım yerinde değil. işimi daha iyi bir hale getirmem, kendimi daha ait hissedeceğim bir yere taşınmam ve sosyalleşmem gerekiyor", "F1_LIFE_SATISFACTION": 3, "F1_PHYSICAL_ACTIVITY": "0"}	{"F2_VALUES": ["power", "hedonism", "achievement", "self_direction", "security", "universalism", "stimulation", "conformity", "benevolence", "tradition"], "F2_BIG5_01": 4, "F2_BIG5_02": 1, "F2_BIG5_03": 4, "F2_BIG5_04": 4, "F2_BIG5_05": 4, "F2_BIG5_06": 4, "F2_BIG5_07": 4, "F2_BIG5_08": 4, "F2_BIG5_09": 4, "F2_BIG5_10": 2, "F2_MBTI_01": "1", "F2_MBTI_02": "1", "F2_MBTI_03": "1", "F2_MBTI_04": "0", "F2_MBTI_05": "0", "F2_MBTI_06": "1", "F2_MBTI_07": "0", "F2_MBTI_08": "0", "F2_MBTI_09": "0", "F2_MBTI_10": "1", "F2_MBTI_11": "0", "F2_MBTI_12": "0", "F2_MBTI_13": "0", "F2_MBTI_14": "1", "F2_MBTI_15": "0", "F2_MBTI_16": "1", "F2_MBTI_17": "0", "F2_MBTI_18": "1", "F2_MBTI_19": "0", "F2_MBTI_20": "1"}	{"F3_FTP_01": 4, "F3_FTP_02": 5, "F3_FTP_03": 4, "F3_FTP_04": 2, "F3_DISC_01": {"most": "3", "least": "0"}, "F3_DISC_02": {"most": "0", "least": "1"}, "F3_DISC_03": {"most": "0", "least": "2"}, "F3_DISC_04": {"most": "0", "least": "1"}, "F3_DISC_05": {"most": "0", "least": "2"}, "F3_DISC_06": {"most": "1", "least": "3"}, "F3_DISC_07": {"most": "1", "least": "2"}, "F3_DISC_08": {"most": "0", "least": "1"}, "F3_DISC_09": {"most": "1", "least": "3"}, "F3_DISC_10": {"most": "0", "least": "3"}, "F3_DAILY_01": 6, "F3_DAILY_02": 6, "F3_DAILY_03": 5, "F3_DAILY_04": "beşiktaşın saçma sapan ve yetersiz futbolcuları transfer etmesi. bir de yeni yapay zeka milyarderlerinin ortaya çıktığını duydum ve ben onlardan biri olmadığım için çok içerledim. belki kıskandım bilmiyorum ama böyle şeyler canımı çok sıkabiliyor. kıskançlık mı yetersizlik duygusu mu bilmiyorum", "F3_STORY_01": "çocukluğumdaki yaz tatilleri. yaşımın 12-15 arası olduğu aralık özellikle. evden uzaklaşıp arkadaşlarımla dere kenarına gittiğimizde veya bir arkadaşımın ailesinin az kullanılan eski evinde akşamları buluştuğumuzda", "F3_STORY_02": "derin düşünme ve analitik konularda zekiyim. başkalarının cesaret edemediği riskler alıyorum ve başardığım dönemler oluyorum. her şeyi başarabilecekmişim gibi bir inancım var. tanıdıkları en bilgili insan benim. özellikle tartışmalarda zekamı kullanış şeklimden etkilenirler", "F3_STORY_03": "daha iyi bir fiziki görünüm (daha uzun boylu daha yakışıklı daha güçlü. bu bana beraberinde daha bi özgüven getirecektir. içimdeki alfa ruhu ortaya çıkaracaktır)\\nzeka seviyemden memnunum ama Dehb veya borderline gibi sorunlarımın olma olasılığı yüksek. bu da benim verimli olmamı çok engelliyor. devamlı kafamı kullanmak bana çok yorucu geliyor. \\ndoğduğum büyüdüğüm aileyi içinde yetiştiğim ülkeyi arkadaşlarımı eğitim aldığım okulları vs hepsini değiştirirdim", "F3_STORY_04": "5 ay askerlikten sonra terhis olacağım günün sabahı hayatımın en mutlu anısı\\n12 günlük tedavilerinin ardında iki abyssian yavru kedime kavuştuğum an\\naşık olduğum kadınların bana karşılık verip benden hoşlandıklarını hissettiğim ilk anlar çok mutlu olurum", "F3_STORY_05": "abimle köyde kavga edip onun kolyesini parçaladığım an. çocuktuk. abim için kıymetliydi. muhtemelen abim haksızdı ama onun için üzülmüştüm\\nbabamdan devamlı fiziki ve piskolojik şiddet gördüğüm zamanlar. evden kurtulmak istiyordum ama beş parasız, köyde yaşayan bir çocuktum sadece. kaçıp sığınabileceğim kadar beni önemseyecek hiç kimse yoktu hayatımda. hala daha yok\\nabim ben ve abimin eşi beraber yaşarken 1 tl dahi paramızın olmadığı, sabah kahvaltı edebileceğimiz hiç bir şeyin olmadığı bir anı var aklımda. o çaresizliği abim ve yengemle birlikte yaşamak çok travmatikti", "F3_STORY_06": "liseyi daha etkili şekilde okuyup iyi bir üniversite kazanıp çok daha erken başlamalıydım hayata\\nüniversitede bölüm seçimlerini daha iyi yapıp sosyal hayat imkanları çok daha yüksek olan bir bir işe yönelik tercihler yapmalıydım.\\nticaret yerine kariyer tercih etmeliydim. zekiydim ve çalışkandım. şu anda muhtemelen büyük bir şirkette CEO falandım . çok geniş bir çevrem vardı, kendim daha donanımlıydım özellikle sosyal beceriler konusunda. dünyam çok daha genişti. buraya kadar olan süreçte de çok daha iyi anılar biriktirmiştim", "F3_STORY_07": "24 yaşındakyekn kızın biri benden hamile olduğunu söylemişti. o kızdan kesinlike bir çocuk istemiyordum ve o çok inatçıydı çocuğu doğurmak konusunda. çok ılımlı yaklaştım mantık dahilinde her türlü doğru tavrı sergilemeye çalıştım. çok akıll danıştım sağa sola ama hiç biri  işe yaramadı. ama bi gün bunu kesin olarak halletmeye karar verdim ve sabah atlayıp ofisine gittim. gayet soğuk aşırı kararlı aşırı umursamaz bir tavrım vardı. doğur istediğğin kadar doğur, 3 tane çocuk da ankarada var 4. yü de sen doğur. zerre umrumda değil dedim. bu esnada emirler yağdırıyordum. kahvaltı hazırla çay getir şunu yap bunu yap. hatta bir defa da seviştik. ve sevişmekten ziyade sex için onu kullandığım belliydi. en son üstümü toplayıp hoşçakal bile demeden çıktım. 1 saat sonra telefon geldi. tamam çocuğu aldıracağım diye. kendimi çok başarılı hissettim. olmam gereken adam oydu bence ama olamadım sonra", "F3_STORY_08": "en büyük umudum AI in ASI ye dönüştüğü bir ütopya. o değilse de büyük bir tech şirkketi kurup hayatımın önceki bölümlerinde yapamadıklarımı bundan sonra yapmak. finansal olarak kendimi güvencede hissetmek. \\nen büyük korkumsa bunların hiç birini yapamadan manevi gücümün tükendiği, finansal olarak çöküp kedilerime bile bakamadığım bir durum. o noktada ölmek en iyi seçenekmiş gibi görünüyor. ayrıca yaşlanmaktan da korkuyorum ", "F3_ATTACH_01": 5, "F3_ATTACH_02": 4, "F3_ATTACH_03": 2, "F3_ATTACH_04": 5, "F3_ATTACH_05": 5, "F3_ATTACH_06": 3, "F3_BELIEF_01": 3, "F3_BELIEF_02": 2, "F3_BELIEF_03": 5, "F3_BELIEF_04": 2, "F3_BELIEF_05": 4, "F3_BELIEF_06": 2, "S3_EMPATHY_1": 4, "S3_EMPATHY_2": 2, "S3_EMPATHY_3": 3, "S3_EMPATHY_4": 4, "S3_EMPATHY_5": 5, "S3_EMPATHY_6": 4, "F3_MEANING_01": 5, "F3_MEANING_02": 4, "F3_MEANING_03": 2, "F3_SOMATIC_01": "2", "F3_SOMATIC_02": ["1", "3", "4"], "S3_CONFLICT_1": [0], "S3_CONFLICT_2": [1], "F3_COG_DIST_01": ["0", "2", "4"], "S3_EMOTION_REG_1": 3, "S3_EMOTION_REG_2": 3, "S3_EMOTION_REG_3": 2, "S3_EMOTION_REG_4": 2, "S3_EMOTION_REG_5": 2, "S3_EMOTION_REG_6": 2, "F3_COPING_MECHANISMS": [0, 2, 4, 3], "F3_SABOTAGE_PATTERNS": [3, 1, 2, 4], "F3_SABOTAGE_AWARENESS": "1"}	[{"id": "block-0", "content": "*Bu rapor 29 Ağustos 2025 22:20 tarihinde oluşturulmuştur.*\\n\\n---\\n\\nHazır mısın? Hadi başlayalım..\\n\\nBu rapor, kendini kandırmanın bittiği yerdir. Amacım sana iyi hissettirmek değil, seni gerçeklerle yüzleştirerek daha güçlü ve etkili kılmak. Dünya bir terapi odası değil, bir rekabet arenası. Zayıflıkların, başkaları veya koşullar tarafından istismar edilecek stratejik dezavantajlardır. Şimdi, zırhını kuşan ve gerçeklerle yüzleşmeye hazırlan. Çünkü potansiyelini israf etmeye devam etmeni izlemeyeceğim.\\n\\n| Özellik / Boyut | Puan |\\n|----------------------------------|----------------------------------------------------------|\\n| **MBTI Tipi** | ISTP |\\n| MBTI Dışadönüklük (E) | 40% |\\n| MBTI İçedönüklük (I) | 60% |\\n| MBTI Duyumsama (S) | 60% |\\n| MBTI Sezgi (N) | 40% |\\n| MBTI Düşünme (T) | 80% |\\n| MBTI Hissetme (F) | 20% |\\n| MBTI Yargılama (J) | 40% |\\n| MBTI Algılama (P) | 60% |\\n| **Big Five - Deneyime Açıklık (O)** | 50% |\\n| **Big Five - Sorumluluk (C)** | 13% |\\n| **Big Five - Dışadönüklük (E)** | 50% |\\n| **Big Five - Uyumluluk (A)** | 50% |\\n| **Big Five - Nevrotiklik (N)** | 75% |\\n| **DISC - Baskınlık (D)** | 70% |\\n| **DISC - Etkileyicilik (I)** | 10% |\\n| **DISC - Sadakat (S)** | 10% |\\n| **DISC - Uygunluk (C)** | 10% |\\n| Bağlanma - Kaygı | 75% |\\n| Bağlanma - Kaçınma | 75% |\\n| Çatışma Stili (Birincil) | Durumsal (Rekabetçi/İşbirlikçi) |\\n| Duygu Düzenleme - Yeniden Değerlendirme| 42% |\\n| Duygu Düzenleme - Bastırma | 25% |\\n| Empati - Duygusal İlgi | 50% |\\n| Empati - Perspektif Alma | 67% |\\n| Anlam ve Amaç Puanı | 67% |\\n| Gelecek Zaman Perspektifi Puanı | 81% |\\n| Baskın Bilişsel Çarpıtmalar | Felaketleştirme, Aşırı Genelleme, -meli, -malı Cümleleri |\\n| Mevcut Bedensel Durum | Kapanma ve Donma |"}, {"id": "block-1", "content": "## Temel Kişiliğiniz\\n\\nProfilin, son derece nadir ve içsel olarak çelişkili bir yapıyı ortaya koyuyor. Kağıt üzerinde, bir **ISTP**'sin: mantıklı, pragmatik, problem çözmeye odaklı bir \\"Usta\\". Aynı zamanda, DISC profilindeki ezici **Baskınlık (D)**, kontrolü ele alma, sonuç elde etme ve yönetme arzusunu haykırıyor. Bu kombinasyon, normal şartlarda durdurulamaz bir teknoloji girişimcisi, bir mucit veya bir stratejist yaratırdı. Ancak senin durumunda, bu güçlü motor, iki kritik arıza nedeniyle boşa çalışıyor: **Aşırı Yüksek Nevrotiklik (%75)** ve **Tehlikeli Düzeyde Düşük Sorumluluk (%13)**.\\n\\nBu, yüksek performanslı bir yarış arabasına sahip olup, lastiklerinin patlak ve yakıt deposunun delik olması gibidir. Zekan ve vizyonun var; büyük resmi görebiliyor ve geleceğe dair güçlü bir umut taşıyorsun (Gelecek Perspektifi: %81). Ancak duygusal fırtınalar (Nevrotiklik) seni sürekli yoldan çıkarıyor ve temel disiplin eksikliği (Sorumluluk) aracın ilerlemesini engelliyor. Sonuç, sürekli bir \\"neredeyse başardım\\" döngüsü, hayal kırıklığı ve boşa harcanan muazzam bir potansiyel.\\n\\nSen, zihninin ve geçmişinin hapishanesine kapatılmış bir stratejistsin. Dışarıdaki krallığı fethetmek için tüm planlara sahipsin ama kendi iç kaleni savunmaktan acizsin. Bu yüzden, seni tanımlayan arketip **\\"Kafesteki Stratejist\\"**tir. Zekan keskin, hırsın gerçek ama seni felç eden görünmez parmaklıklar var: İşlenmemiş travma, yerleşmiş disiplinsizlik ve derin bir terk edilme korkusu."}, {"id": "block-2", "content": "## Güçlü Yönleriniz\\n\\nZayıflıklarına odaklanmadan önce, hangi silahlara sahip olduğunu netleştirelim. Bunlar, doğru kullanıldığında seni ileriye taşıyacak araçlardır.\\n\\n*   **Analitik ve Stratejik Zeka:** Senaryoları analiz etme, mantıksal bağlantılar kurma ve karmaşık sorunlara çözüm bulma konusunda doğal bir yeteneğin var. Düşünme (T) puanının %80 olması, kararlarını duygusal dalgalanmalardan (eğer yönetebilirsen) arındırıp objektif kriterlere dayandırabildiğini gösteriyor. Tartışmalarda zekanı kullanma şeklinden insanların etkilenmesi boşuna değil.\\n\\n*   **Vizyoner Gelecek Odaklılığı:** %81 gibi yüksek bir Gelecek Zaman Perspektifi puanı, bugünkü eylemlerinin yarını nasıl şekillendirdiğini derinden anladığını gösteriyor. Bu, uzun vadeli hedefler belirlemeni ve bu hedeflere ilhamla bağlanmanı sağlar. Büyük bir teknoloji şirketi kurma hayalin, bu vizyoner gücün bir kanıtıdır.\\n\\n*   **Girişimci Cesareti ve Risk Alma:** Yüksek Baskınlık (D) profilin ve kendi anlatımın, başkalarının çekindiği yerlerde adım atmaktan korkmadığını gösteriyor. Belirsizliğe toleransın ve kontrolü ele alma içgüdün, bir girişimci için temel yakıttır.\\n\\n*   **Bilişsel Empati (Perspektif Alma):** Duygusal olarak empati kurmakta zorlansan da (%50 Duygusal İlgi), bir durumu başkasının gözünden görme ve argümanlarını anlama yeteneğin (%67 Perspektif Alma) oldukça gelişmiş. Bu, müzakere ve strateji gerektiren durumlarda sana avantaj sağlar."}, {"id": "block-3", "content": "## Kör Noktalar ve Riskler\\n\\nBurası acı gerçeklerin başladığı yer. Bunlar küçük kusurlar değil, seni tekrar tekrar başarısızlığa uğratan, seni öngörülebilir ve savunmasız kılan sistemik zayıflıklardır.\\n\\n### 1. Felç Eden Disiplinsizlik\\n\\n*   **Desen:** Sorumluluk (Conscientiousness) puanın %13. Bu istatistiksel bir anormallik değil, bir alarm sireni. Planlama, organize olma, detaylara dikkat etme ve en önemlisi, bir işi sonuna kadar götürme konusunda kronik bir yetersizlik içindesin. Erteleme, senin için bir alışkanlık değil, bir yaşam biçimi.\\n*   **Maliyet:** Bu, büyük hedeflerinin önündeki en büyük engel. Tech startup'lar fikirlerle değil, amansız ve sıkıcı bir uygulama ile inşa edilir. Bu özellik, finansal istikrarsızlığa, yarım kalmış projelere ve en sonunda kendine olan saygını yitirmene neden olur. \\"Ticaret yerine kariyer seçmeliydim\\" pişmanlığın, bu içsel gerçeği fark etmenin bir yansımasıdır; dış bir yapının seni disipline sokacağını umuyordun.\\n*   **Altta Yatan Sebep ve Bilinçdışı Kazanç:** Bu tembellik değil, bir savunma mekanizması. **Bilinçdışı Kazancın**, egonu korumaktır. Eğer bir işe \\"gerçekten\\" tüm gücünle asılmazsan ve başarısız olursan, her zaman \\"isteseydim yapardım\\" bahanesine sığınabilirsin. Bu, tüm potansiyelini ortaya koyup yine de yetersiz kalma korkusundan seni koruyan bir kalkandır.\\n\\n### 2. Gücün Karanlık Yüzü\\n\\n*   **Desen:** Yüksek Baskınlık (D) ve \\"en çok gurur duyduğun anı\\" olarak anlattığın hikaye, tehlikeli bir dinamiği ortaya koyuyor. Bir kadını soğukkanlı bir manipülasyonla kürtaja zorladığın anı, \\"olman gereken adam\\" olarak idealize ediyorsun. Bu, gücü, kontrolü ve başkaları üzerinde tahakküm kurmayı, zayıflığa karşı nihai panzehir olarak gördüğünü gösteriyor.\\n*   **Maliyet:** Bu zihniyet, gerçek ve sürdürülebilir başarıyı sabote eder. Güven üzerine kurulu ortaklıklar kurmanı, yetenekli insanları kendine çekmeni ve sağlıklı ilişkiler yaşamanı imkansız hale getirir. Bu \\"alfa\\" persona, yalnız bir kral yaratır; etrafında korkuyla itaat edenler olur ama asla sadakatle bağlı olanlar olmaz.\\n*   **Altta Yatan Sebep ve Bilinçdışı Kazanç:** Bu, babandan gördüğün fiziksel ve psikolojik şiddete ve çocukluğundaki mutlak çaresizliğe karşı geliştirilmiş travmatik bir tepkidir. Asla bir daha o kadar güçsüz hissetmemek için, gücün en acımasız ve kontrolcü biçimine sığınıyorsun. **Bilinçdışı Kazancın:** Bu soğuk ve umursamaz tavır, seni o çaresiz, korkmuş çocuk olmanın dehşetinden koruyan bir zırhtır.\\n\\n### 3. Korku Temelli Bağlanma\\n\\n*   **Desen:** %75 Kaygı ve %75 Kaçınma. Bu, \\"Korkulu-Kaçınmacı\\" bağlanma stilidir. Hem yakınlığa ve onaya umutsuzca ihtiyaç duyuyorsun (Kaygı) hem de biri sana çok yaklaştığında kendini tehdit altında hissedip onu itiyorsun (Kaçınma). \\"İyi anlaşabildiğim bir kız arkadaşımın olması\\" hedefinle bu desen doğrudan çelişir.\\n*   **Maliyet:** Yalnızlık, istikrarsız ve dramatik ilişkiler, ve \\"kaçıp sığınabileceğim kadar beni önemseyecek hiç kimse yok hayatımda\\" hissinin kendini gerçekleştiren bir kehanete dönüşmesi. İlişkileri, onlar seni terk etmeden önce senin sabote etmenle sonuçlanır.\\n*   **Altta Yatan Sebep:** Çocukluktaki istismar ve ihmal. Temel inancın, sevilmeye layık olmadığın (\\"kusurlu ve sevilmeye layık olmadığıma inanırım\\" - 5/5) ve eninde sonunda terk edileceğin (\\"insanların eninde sonunda beni hayal kırıklığına uğratacağına... inanırım\\" - 4/5)."}, {"id": "block-4", "content": "## İlişkiler ve Sosyal Dinamikler\\n\\nİlişkilerdeki temel dinamiğin bir \\"itme-çekme\\" oyunudur. Birini istersin, onu elde etmek için zekanı ve karizmanı kullanırsın. Ancak yakınlık arttıkça, içindeki alarm zilleri çalmaya başlar. Terk edilme korkun (Kaygı) tavan yapar. Bu korkuyla başa çıkmak için, kontrolü ele almak adına uzaklaşır, duvarlar örer veya partnerini itersin (Kaçınma). Bu döngü, partnerin için kafa karıştırıcı ve yorucudur ve genellikle ilişkinin sonunu getirir.\\n\\nDuygularını etkili bir şekilde ne yeniden değerlendirebiliyor (%42) ne de bastırabiliyorsun (%25). Bu, duygularının ham ve yoğun bir şekilde ortaya çıktığı anlamına gelir. Bu durum, Yüksek Nevrotikliğinle birleştiğinde, ilişkilerde küçük anlaşmazlıkları büyük krizlere dönüştürme potansiyeline sahip."}, {"id": "block-5", "content": "## Kariyer ve Çalışma Tarzı\\n\\nKariyerindeki temel çelişki şudur: Bir imparatorluk kurmak isteyen bir lidersin (Yüksek D) ama bir imparatorluğu ayakta tutan günlük, sıkıcı işlerden nefret eden bir askersin (Düşük C). Sen bir \\"fikir adamısın\\". Başlangıç enerjin yüksek, vizyonun parlak. Ancak uygulama, takip, bürokrasi ve rutin gerektiren her şey senin için bir eziyet.\\n\\nBu yüzden evden, tek başına çalışmak senin için hem bir sığınak hem de bir tuzak. Sığınak, çünkü kimseye hesap vermek zorunda değilsin. Tuzak, çünkü seni disipline edecek ve sorumlu tutacak hiçbir dış yapı yok. Başarın, Düşük Sorumluluğunu telafi edecek sistemler kurmana veya bu açığı kapatacak ortaklar bulmana bağlı. Aksi takdirde, parlak fikirlerle dolu bir mezarlık inşa etmeye devam edersin."}, {"id": "block-6", "content": "## Duygusal Desenler ve Stres\\n\\nStres seviyen 7/10, hayat memnuniyetin ise 3/10. Bu rakamlar, iç dünyanda bir savaş olduğunu gösteriyor. Yüksek Nevrotikliğin, küçük tetikleyicileri büyük tehditler olarak algılamana neden oluyor. Başka birinin başarısını duyduğunda (\\"yeni yapay zeka milyarderleri\\") hissettiğin yoğun \\"içerleme\\" ve \\"kıskançlık\\", kendi yetersizlik duygularının ne kadar yüzeye yakın olduğunun bir kanıtı.\\n\\nBedenin bu stresi taşıyor. Midendeki düğüm, sıktığın çene ve kalp çarpıntıların, sinir sisteminin sürekli \\"Savaş ya da Kaç\\" modunda olduğunun fiziksel işaretleri. Ancak mevcut durumun daha da endişe verici: \\"Kapanma ve Donma\\". Bu, sinir sisteminin tehditle başa çıkamadığı ve pes ettiği noktadır. Uyuşukluk, içe kapanma ve boşluk hissi... Bu, çocukluktaki çaresizliğin bedensel bir yankısıdır. Hareketsiz yaşam tarzın bu durumu daha da kötüleştiriyor."}, {"id": "block-7", "content": "## Hayat Kalıpları ve Muhtemel Tuzaklar\\n\\nHayatındaki ana kalıp, \\"parlama ve sönme\\" döngüsüdür. Büyük bir hevesle yeni bir projeye başlarsın, ilk engelleri zekanla aşarsın, ancak uzun vadeli sebat ve sıkıcı detaylar gerektiğinde enerjin tükenir ve proje ölür. Sonra kendini suçlar, hayal kırıklığına uğrar ve bir sonraki \\"kurtarıcı\\" fikri beklersin.\\n\\nEn büyük tuzağın, problemin \\"dışarıda\\" olduğuna inanmaktır. Eğer doğru fikir, doğru ortak, doğru şehir veya doğru kadın gelirse her şeyin düzeleceğini düşünüyorsun. Ama sorun bu değil. Sorun, işletim sisteminin kendisinde. Yeni bir yazılım yüklemeye çalışıyorsun ama donanım (duygusal düzenleme ve disiplin becerilerin) çökmüş durumda."}, {"id": "block-8", "content": "## Yol Ayrımı: İki Muhtemel Gelecek\\n\\nBugün durduğun yerden, önümüzdeki 5 yıl için iki net yol görünüyor. Seçim senin.\\n\\n### Patika 1: 'Aynı Kalan' Gelecek\\n\\nEğer hiçbir şeyi temelden değiştirmezsen, 5 yıl sonra 52 yaşında olacaksın. Muhtemelen birkaç \\"neredeyse oluyordu\\" teknoloji girişimi hikayen daha olacak. Hâlâ \\"bir sonraki büyük fikrin\\" peşinde koşuyor olacaksın. Finansal durumun istikrarsız, stres seviyen kronik olarak yüksek olacak. \\"İyi anlaşabildiğin bir kız arkadaş\\" hayalin, birkaç başarısız ve dramatik denemeden sonra daha da uzaklaşmış olacak. İçindeki o parlak stratejist, pişmanlık ve \\"eğer yapsaydım\\"larla dolu bir kafeste, giderek daha öfkeli ve umutsuz bir hale gelecek. Çocukluğunun çaresizliği, yetişkinliğinin acı gerçeğine dönüşecek.\\n\\n### Patika 2: 'Potansiyel' Gelecek\\n\\nEğer bu raporu bir hakaret olarak değil, bir savaş çağrısı olarak kabul edersen, her şey değişebilir. Önümüzdeki 1-2 yılı, yeni bir iş kurmaya değil, kendini yeniden inşa etmeye adarsın. Travmalarınla yüzleşmek için profesyonel yardım alırsın. Disiplini bir ilham anı olarak değil, her gün yapılan sıkıcı bir kas antrenmanı olarak görmeye başlarsın. Fiziksel olarak güçlenirsin. 5 yıl sonra, 52 yaşında, belki daha küçük ama istikrarlı ve kârlı bir işin başında olursun. Çünkü bir fikri başlatmanın değil, bir işi sürdürmenin ne demek olduğunu öğrenmişsindir. Duygusal olarak daha dengeli, daha az reaktif bir adam olursun. Ve bu istikrar, hayatına gerçekten sağlıklı ve destekleyici bir ilişki çekmeni sağlar. Kafesteki stratejist sonunda özgür kalır, çünkü savaşması gereken krallığın dışarıda değil, içeride olduğunu anlamıştır."}, {"id": "block-9", "content": "## Uygulanabilir İleriye Dönük Yol Haritası\\n\\nBunlar iyi niyetli tavsiyeler değil, emirlerdir. Potansiyelini israf etmeyi bırakmak istiyorsan, bunları yapacaksın.\\n\\n1.  **Profesyonel Yardım Al (Pazarlıksız):** Kendi başına çözemeyeceğin derin travmaların var. Babandan gördüğün şiddet, terk edilme şemaların ve çarpık güç algın, bir terapistle, özellikle EMDR veya şema terapi gibi yöntemlerle çalışılmalıdır. Bu bir seçenek değil, bir zorunluluk.\\n\\n2.  **Sorumluluğu Kas Gibi Çalıştır:** Disiplin, ilhamla gelmez. Tekrarla gelir. Her gün, yatağını toplamak gibi küçücük bir şeyle başla. Ardından, 15 dakika boyunca kesintisiz çalış. Sadece 15 dakika. Bunu bir ay boyunca her gün yap. Amacın bir startup kurmak değil, \\"sözünü tutma\\" kasını geliştirmek.\\n\\n3.  **Disiplini Dışsallaştır:** Madem içinde yok, dışarıdan al. Bir iş koçu tut. Seni her hafta arayıp hesap soracak bir arkadaşınla anlaş. Trello, Asana gibi proje yönetim araçlarını kullan ve görevlerini en küçük adımlara böl. Kendi iradene güvenmeyi bırak, sistemlere güven.\\n\\n4.  **Bedenini Harekete Geçir:** \\"Kapanma\\" durumundan çıkmanın en hızlı yolu bedeni hareket ettirmektir. Haftada 3 gün ağırlık antrenmanı yapmaya başla. Bu, sadece fiziksel görünümün için değil (ki bu senin için önemli), aynı zamanda sinir sistemini yeniden düzenlemek, stresi azaltmak ve kendine olan güvenini inşa etmek için kritiktir.\\n\\n5.  **\\"Güç\\" Tanımını Yeniden Yaz:** Gurur duyduğun o anıyı bir kenara bırak. Gerçek güç, başkalarını manipüle etmek değil, kendi içindeki kaosu yönetebilmektir. Gerçek alfa, duygularından kaçan değil, onlarla yüzleşip onları yönetebilen adamdır. Bu yeni tanımı benimse.\\n\\n6.  **Duygu Düzenleme Pratiği Yap:** Günde 5 dakika. Sadece otur ve nefesini izle. Zihnine gelen düşünceleri ve duyguları yargılamadan gözlemle. Bu, reaktif olmak yerine yanıt vermeyi öğrenmenin ilk adımıdır. Stres anında, midendeki düğüme veya çenendeki gerginliğe odaklan. Sadece fark et. Bu, bedeninle yeniden bağlantı kurmanı sağlayacak.\\n\\n7.  **Okumayı ve Öğrenmeyi Stratejikleştir:** Bilgili olman bir güç. Ancak bunu yapılandır. \\"Attachment Theory\\" (Bağlanma Kuramı), \\"Cognitive Behavioral Therapy\\" (Bilişsel Davranışçı Terapi) ve \\"Atomic Habits\\" (Atomik Alışkanlıklar) gibi konuları oku. Problemlerini entelektüel olarak anlamak, çözüm için motivasyonunu artıracaktır.\\n\\n8.  **Düşük Riskli Sosyal Arenalara Gir:** Bir hobi kursuna yazıl. Bir spor takımına katıl. Amacın bir kız arkadaş bulmak değil. Amacın, insanlarla beklentisiz, düşük basınçlı ortamlarda etkileşim kurma alıştırması yapmak. Bu, bağlanma korkularını yavaş yavaş desensitize etmene yardımcı olur."}, {"id": "block-10", "content": "## Kendi Sözlerinizden: Anılar ve Anlam\\n\\nHikayelerin, kim olduğunun ham verileridir. Seninkiler, birbiriyle savaşan iki temel temayı ortaya koyuyor: **Özgürlük/Kurtuluş** ve **Kapana Kısılma/Çaresizlik**.\\n\\nMutlu anıların – askerliğin bitişi, arkadaşlarla evden kaçışlar, kedilerine kavuşman – hepsi bir tür esaretten kurtuluş anlarıdır. Bu, hayatındaki en derin arzunun **özgürlük** olduğunu gösteriyor. En kötü anıların ise tam tersi: Babanın şiddetinden kaçamayan beş parasız bir çocuk, yoksulluğun içinde kapana kısılmış bir genç. Bu deneyimler, \\"Terk Edilme\\" ve \\"Kusurluluk\\" şemalarını ruhuna kazımış. \\"Kaçıp sığınabileceğim... hiç kimse yoktu hayatımda. hala daha yok\\" cümlen, bu yaranın ne kadar taze ve derin olduğunun kanıtıdır.\\n\\nEn çok gurur duyduğun anı, bu dinamiğin en net resmidir. İstenmeyen bir hamilelik durumunda kendini \\"kapana kısılmış\\" hissettin. Verdiğin tepki, çocuklukta sana yapılanın aynısını başkasına yapmaktı: Soğuk, kontrolcü ve acımasız bir güç gösterisiyle kendini durumdan \\"kurtarmak\\". Bu, senin için bir zafer anıydı çünkü o an için, kurban değil, fail sendin. Bu, travmanın kendini nasıl tekrar ettiğinin trajik bir örneğidir.\\n\\nHayat hikayen, psikolojide \\"Kirlenme Anlatısı\\" (Contamination Narrative) dediğimiz şeye uyuyor: iyi bir başlangıç (zekan, potansiyelin) kötü bir olayla (travma, disiplinsizlik) \\"kirlenir\\" ve olumsuz bir sonuca yol açar. Senin görevin, bu anlatıyı yeniden yazmaktır. Kurtuluşun, başkalarını kontrol etmekte değil, kendi içindeki o çaresiz çocuğu iyileştirmekte ve ona bugün ihtiyaç duyduğu güvenliği ve yapıyı sağlamaktadır. Anlam ve Amaç puanının (%67) orta düzeyde olması, bir misyonun olduğunu hissettiğini ama mevcut hayatının bu misyonu yansıtmadığını gösteriyor. Anlam, bu iki ucu birleştirdiğinde bulunacaktır."}, {"id": "block-11", "content": "## Bulgular, Temeller ve Kanıtlar\\n\\nBu analiz, sağladığın yanıtlara dayanarak oluşturulmuş bütünsel bir portredir. Kişiliğinin temel yapısını anlamak için Myers-Briggs Tip Göstergesi (MBTI), Beş Faktör Kişilik Modeli (Big Five) ve DISC gibi köklü psikometrik araçlardan yararlanılmıştır. Bu temel yapı üzerine, ilişkilerdeki derin kalıplarını ortaya çıkarmak için Bağlanma Kuramı ve Şema Terapi prensipleri entegre edilmiştir.\\n\\nDuygusal ve bilişsel alışkanlıkların, Duygu Düzenleme, Empati ve Bilişsel Çarpıtmalar üzerine yapılan araştırmalarla değerlendirilmiştir. Geleceğe bakış açın ve hayattaki anlam arayışın, sırasıyla Gelecek Zaman Perspektifi ve Logoterapi (Anlam Terapisi) çerçevelerinde incelenmiştir. Son olarak, kişisel anlatıların ve anıların, kimliğini ve temel motivasyonlarını şekillendiren yaşam öyküsü temalarını belirlemek için analiz edilmiştir.\\n\\nBu çok katmanlı yaklaşım, sadece yüzeysel davranışlarını değil, aynı zamanda bu davranışların altında yatan derin inançları, duygusal sürücüleri ve bilinçdışı kalıpları da aydınlatmayı amaçlamaktadır. Sonuçlar, bir \\"etiketleme\\" aracı değil, kendini anlaman ve stratejik olarak geliştirmen için tasarlanmış bir yol haritasıdır."}, {"id": "block-12", "content": "## Yasal Uyarı\\n\\nBu rapor yalnızca kişisel gelişim ve bilgilindirme amaçlıdır. Tıbbi veya klinik bir tanı değildir ve profesyonel yardımın yerini alamaz. Bu rapora dayanarak alacağınız tüm kararlar kendi sorumluluğunuzdadır."}]	2025-08-29 22:18:53.335455
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
-- Data for Name: coupon_usage; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.coupon_usage (id, coupon_id, user_id, used_at, subscription_id) FROM stdin;
07ad46fd-d659-4c92-8d90-2db91e936683	a03e9436-aa9d-44bd-a676-6cd89f6ecfc7	ebe6eee2-01ae-4753-9737-0983b0330880	2025-08-23 00:16:38.336299+03	\N
\.


--
-- Data for Name: coupons; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.coupons (id, code, description, type, plan_id, duration_months, discount_percent, credit_amount, credit_type, max_uses, uses_count, one_time_per_user, valid_from, valid_until, is_active, created_at, updated_at) FROM stdin;
a03e9436-aa9d-44bd-a676-6cd89f6ecfc7	CCBEDAVA	1 Aylık Standart Paket - Cogni Coach Deneme Kampanyası	free_subscription	standard	1	\N	\N	\N	\N	3	t	2025-08-22 23:37:42.216206+03	2025-09-22 23:37:42.216206+03	t	2025-08-22 23:37:42.216206+03	2025-08-22 23:37:42.216206+03
e4940814-6729-4fb8-80ce-8ea5b2bd3452	TEST2025	Test Kuponu - 1 Aylık Standart Paket	free_subscription	standard	1	\N	\N	\N	\N	0	t	2025-08-25 00:34:52.130477+03	2025-09-24 00:34:52.130477+03	t	2025-08-25 00:34:52.130477+03	2025-08-25 00:34:52.130477+03
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

COPY public.items (id, form, section, subscale, text_tr, type, options_tr, reverse_scored, scoring_key, weight, notes, display_order, test_type, text_en, options_en, conditional_on) FROM stdin;
F2_BIG5_01	Form2_Kisilik	Mizaç	Openness	Yeni fikirlere ve deneyimlere açığımdır	Likert5		0	\N	1	\N	1	BIG_FIVE	I am open to new ideas and experiences	\N	\N
F2_BIG5_02	Form2_Kisilik	Mizaç	Conscientiousness	Detaylara dikkat eder planlı ve organize biriyimdir	Likert5		0	\N	1	\N	2	BIG_FIVE	I pay attention to details and am organized	\N	\N
F2_BIG5_03	Form2_Kisilik	Mizaç	Extraversion	Sosyal ortamlarda enerjik ve konuşkanımdır	Likert5		0	\N	1	\N	3	BIG_FIVE	I am energetic and talkative in social settings	\N	\N
F2_BIG5_04	Form2_Kisilik	Mizaç	Agreeableness	Genellikle başkalarının duygularına karşı duyarlı ve yardımseverimdir	Likert5		0	\N	1	\N	4	BIG_FIVE	I am generally sensitive and helpful to others' feelings	\N	\N
F2_BIG5_05	Form2_Kisilik	Mizaç	Neuroticism	Kolayca endişelenir veya strese girerim	Likert5		0	\N	1	\N	5	BIG_FIVE	I easily worry or get stressed	\N	\N
F2_BIG5_06	Form2_Kisilik	Mizaç	Openness	Geleneksel ve alışılmış yöntemleri tercih ederim	Likert5		1	\N	1	\N	6	BIG_FIVE	I prefer traditional and conventional methods	\N	\N
F2_MBTI_06	Form2_Kisilik	Bilişsel Tercih	S-N	Yeni bir şey öğrenirken hangisini tercih edersiniz?	SingleChoice	A) Somut gerçeklere pratik uygulamalara ve adım adım ilerleyen net talimatlara odaklanmayı|B) Teorik altyapıya büyük resme ve fikirler arasındaki bağlantıları anlamaya odaklanmayı	0	\N	1	\N	16	MBTI	When learning something new which do you prefer?	A) Focusing on concrete facts practical applications and clear step-by-step instructions|B) Focusing on theoretical background big picture and understanding connections between ideas	\N
F2_MBTI_07	Form2_Kisilik	Bilişsel Tercih	S-N	Bir olayı birine anlatırken...	SingleChoice	A) Olayın spesifik detaylarını kimin ne dediğini ve ne olduğunu olduğu gibi aktarmaya eğilimliyimdir|B) Olayın bende bıraktığı izlenimi anlamını ve altında yatan dinamikleri anlatmaya eğilimliyimdir	0	\N	1	\N	17	MBTI	When telling someone about an event...	A) I tend to convey specific details who said what and what happened as is|B) I tend to tell the impression meaning and underlying dynamics	\N
F2_MBTI_08	Form2_Kisilik	Bilişsel Tercih	S-N	Problem çözerken yaklaşımınız nedir?	SingleChoice	A) Mevcut ve kanıtlanmış yöntemleri kullanarak gerçekçi ve uygulanabilir çözümler bulurum|B) Olasılıkları ve yeni olasılıkları düşünerek yenilikçi ve alışılmadık çözümler ararım	0	\N	1	\N	18	MBTI	What is your problem-solving approach?	A) I find realistic and applicable solutions using existing proven methods|B) I look for innovative and unusual solutions by thinking about possibilities	\N
F2_MBTI_09	Form2_Kisilik	Bilişsel Tercih	S-N	Hangisi size daha çok hitap eder?	SingleChoice	A) Ayrıntılarda ustalık gizlidir|B) Hayal gücü bilgiden daha önemlidir	0	\N	1	\N	19	MBTI	Which appeals to you more?	A) Mastery lies in the details|B) Imagination is more important than knowledge	\N
F2_MBTI_10	Form2_Kisilik	Bilişsel Tercih	S-N	Genel olarak daha çok dikkat ettiğiniz şey...	SingleChoice	A) Gördüğüm duyduğum dokunduğum somut gerçeklerdir|B) Sezgilerim içgüdülerim ve olayların gelecekte nereye varabileceğine dair olasılıklardır	0	\N	1	\N	20	MBTI	What you generally pay more attention to...	A) Concrete facts I see hear and touch|B) My intuitions instincts and possibilities of where events might lead	\N
F2_BIG5_07	Form2_Kisilik	Mizaç	Conscientiousness	İşlerimi sık sık erteler dağınık çalışırım	Likert5		1	\N	1	\N	7	BIG_FIVE	I often procrastinate and work in a disorganized manner	\N	\N
F2_BIG5_08	Form2_Kisilik	Mizaç	Extraversion	Kalabalık sosyal ortamlardan sonra kendimi tükenmiş hissederim	Likert5		1	\N	1	\N	8	BIG_FIVE	I feel exhausted after crowded social settings	\N	\N
F2_BIG5_09	Form2_Kisilik	Mizaç	Agreeableness	Kendi çıkarlarımı başkalarınınkinden önde tutmaya eğilimliyimdir	Likert5		1	\N	1	\N	9	BIG_FIVE	I tend to prioritize my own interests over others	\N	\N
F2_BIG5_10	Form2_Kisilik	Mizaç	Neuroticism	Genellikle sakin ve duygusal olarak dengeliyimdir	Likert5		1	\N	1	\N	10	BIG_FIVE	I am generally calm and emotionally balanced	\N	\N
F2_VALUES	Form2_Kisilik	Motivasyon		Bu değerleri sizin için en önemliden en az önemliye doğru sıralayınız (1=en önemli 10=en az önemli)	Ranking	Başarı|Güç|Heyecan|Özyönelim|İyilikseverlik|Evrenselcilik|Güvenlik|Gelenek|Uyum|Hazcılık	0	\N	1	\N	31	VALUES	Rank these values from most to least important to you (1=most 10=least)	Achievement|Power|Excitement|Self-direction|Benevolence|Universalism|Security|Tradition|Conformity|Hedonism	\N
F2_MBTI_12	Form2_Kisilik	Bilişsel Tercih	T-F	Bir arkadaşınız derdini anlattığında ilk tepkiniz ne olur?	SingleChoice	A) Sorunu analiz edip mantıklı çözüm yolları sunmaya çalışmak|B) Onu anladığımı hissettirip duygusal destek ve teselli vermek	0	\N	1	\N	22	MBTI	Your first reaction when a friend tells their troubles?	A) Trying to analyze the problem and offer logical solutions|B) Making them feel understood and giving emotional support and comfort	\N
F2_MBTI_13	Form2_Kisilik	Bilişsel Tercih	T-F	Size söylense hangisi daha büyük bir iltifat olurdu?	SingleChoice	A) Sen çok mantıklı ve adil bir insansın|B) Sen çok şefkatli ve anlayışlı bir insansın	0	\N	1	\N	23	MBTI	Which would be a bigger compliment if said to you?	A) You are a very logical and fair person|B) You are a very compassionate and understanding person	\N
F2_MBTI_14	Form2_Kisilik	Bilişsel Tercih	T-F	Bir eleştiri yapmanız gerektiğinde...	SingleChoice	A) Doğru ve dürüst olmak adına gerçeği olduğu gibi söylemeyi tercih ederim|B) Karşımdakini kırmamak için sözlerimi dikkatle seçer ve daha diplomatik bir dil kullanırım	0	\N	1	\N	24	MBTI	When you need to give criticism...	A) I prefer to tell the truth as it is for the sake of being correct and honest|B) I choose my words carefully and use more diplomatic language to not hurt others	\N
F2_MBTI_15	Form2_Kisilik	Bilişsel Tercih	T-F	Bir grubun iyiliği için bir karar alınması gerektiğinde...	SingleChoice	A) En doğru ve etkili sonucun ne olduğuna odaklanırım bazı kişiler bundan hoşnut olmasa bile|B) Gruptaki herkesin kendini duyulmuş ve değerli hissetmesini sağlamaya uyumu korumaya odaklanırım	0	\N	1	\N	25	MBTI	When a decision needs to be made for the good of a group...	A) I focus on the most correct and effective outcome even if some people are not happy|B) I focus on making everyone feel heard and valued maintaining harmony	\N
F3_BELIEF_01	Form3_Davranis	Derin İnançlar	Internal	Hayatımda başıma gelenlerin kontrolü büyük ölçüde bendedir	Likert5		0	\N	1	\N	21	LOCUS_OF_CONTROL	I have control over most things that happen in my life	\N	\N
F3_BELIEF_02	Form3_Davranis	Derin İnançlar	Failure	Ne kadar çabalarsam çabalayayım sonunda başarısız olacağımı hissederim	Likert5		0	\N	1	\N	22	SCHEMA	No matter how hard I try I feel I will ultimately fail	\N	\N
F3_BELIEF_03	Form3_Davranis	Derin İnançlar	Defectiveness	Derinlerde bir yerde kusurlu ve sevilmeye layık olmadığıma inanırım	Likert5		0	\N	1	\N	23	SCHEMA	Deep down I believe I am flawed and unworthy of love	\N	\N
F3_BELIEF_04	Form3_Davranis	Derin İnançlar	External	Hayatta başıma gelen iyi şeylerin çoğu şans eseridir	Likert5		0	\N	1	\N	24	LOCUS_OF_CONTROL	Most good things that happen to me are due to luck	\N	\N
F3_BELIEF_05	Form3_Davranis	Derin İnançlar	Abandonment	İnsanların eninde sonunda beni hayal kırıklığına uğratacağına veya terk edeceğine inanırım	Likert5		0	\N	1	\N	25	SCHEMA	I believe people will eventually disappoint or abandon me	\N	\N
F3_BELIEF_06	Form3_Davranis	Derin İnançlar	Subjugation	Kendi ihtiyaçlarımı ifade edersem başkalarını kaybedeceğimden veya cezalandırılacağımdan korkarım	Likert5		0	\N	1	\N	26	SCHEMA	I fear losing others or being punished if I express my needs	\N	\N
F3_ATTACH_01	Form3_Davranis	İlişki Şablonları	Anxiety	Partnerimin beni terk edeceğinden sık sık endişe duyarım	Likert5		0	\N	1	\N	27	ATTACHMENT	I often worry that my partner will leave me	\N	\N
F3_ATTACH_03	Form3_Davranis	İlişki Şablonları	Anxiety	Partnerimin bana değer verdiği kadar benim ona değer vermediğimden korkarım	Likert5		0	\N	1	\N	29	ATTACHMENT	I fear my partner doesn't value me as much as I value them	\N	\N
F3_ATTACH_02	Form3_Davranis	İlişki Şablonları	Avoidance	Başkalarına duygusal olarak çok yakınlaşmaktan rahatsız olurum	Likert5		0	\N	1	\N	28	ATTACHMENT	I feel uncomfortable getting emotionally close to others	\N	\N
F3_ATTACH_04	Form3_Davranis	İlişki Şablonları	Avoidance	Bağımsızlığımı ve kendi kendime yetmeyi her şeyden önemli görürüm	Likert5		0	\N	1	\N	30	ATTACHMENT	I value my independence and self-sufficiency above everything	\N	\N
F3_SOMATIC_01	Form3_Davranis	Bedensel Farkındalık	PolyvagalState	Şu an, bu saniyede, kendinizi en çok hangisine yakın hissediyorsunuz?	SingleChoice	Güvende ve Bağlantıda (Sakin, sosyal, dünyaya açık ve meraklı)|Savaş ya da Kaç (Enerjik, tetikte, endişeli veya gergin)|Kapanma ve Donma (Yorgun, içe kapanık, uyuşuk veya boşlukta)	0	\N	1	\N	\N	SOMATIC_AWARENESS	Right now, at this moment, which do you feel closest to?	Safe and Connected (Calm, social, open and curious about the world)|Fight or Flight (Energetic, alert, anxious or tense)|Shutdown and Freeze (Tired, withdrawn, numb or empty)	\N
F3_COG_DIST_01	Form3_Davranis	Düşünce Hataları		Stresli veya olumsuz bir durum yaşadığınızda, aşağıdaki düşünce alışkanlıklarından hangilerini yapmaya en çok eğilimli olursunuz? (En fazla 4 tane seçin)	MultiSelect4	Felaketleştirme (En kötü senaryoya inanmak)|Ya Hep Ya Hiç Düşüncesi (Olayları siyah-beyaz görmek)|Aşırı Genelleme (Tek bir olayı bitmeyecek bir yenilgi gibi görmek)|Zihin Okuma (Kanıt olmadan başkalarının ne düşündüğünü varsaymak)|-meli, -malı Cümleleri (Katı ve gerçekçi olmayan kurallar koymak)|Kişiselleştirme (Sizinle ilgisi olmayan olayların sorumluluğunu üstlenmek)	0	\N	1	\N	\N	COGNITIVE_DISTORTIONS	When you experience a stressful or negative situation, which of the following thinking habits are you most prone to? (Select up to 4)	Catastrophizing (Believing in worst case scenarios)|All-or-Nothing Thinking (Seeing things in black and white)|Overgeneralization (Viewing a single event as a never-ending defeat)|Mind Reading (Assuming what others think without evidence)|Should Statements (Setting rigid and unrealistic rules)|Personalization (Taking responsibility for events unrelated to you)	\N
F3_ATTACH_05	Form3_Davranis	İlişki Şablonları	Anxiety	Partnerimden istediğim kadar yakınlık ve ilgi göremediğimde hayal kırıklığına uğrarım	Likert5		0	\N	1	\N	31	ATTACHMENT	I get disappointed when I don't receive the closeness and attention I want from my partner	\N	\N
F3_ATTACH_06	Form3_Davranis	İlişki Şablonları	Avoidance	Başkalarına güvenmekte ve onlara bel bağlamakta zorlanırım	Likert5		0	\N	1	\N	32	ATTACHMENT	I have difficulty trusting and relying on others	\N	\N
F3_STORY_01	Form3_Davranis	Yaşam Anlatısı		Hayatınızda kendinizi gerçekten canlı özgür ve tam anlamıyla kendiniz gibi hissettiğiniz bir anı veya dönemi anlatır mısınız? Bu anı bu kadar özel kılan neydi?	OpenText		0	\N	1	\N	33	NARRATIVE	Describe a moment when you felt truly alive free and completely yourself	\N	\N
F3_STORY_02	Form3_Davranis	Yaşam Anlatısı		Başkalarının sizde en çok takdir ettiğini söylediği veya kendinizle sessizce gurur duymanızı sağlayan üç temel özelliğiniz nedir?	OpenText		0	\N	1	\N	34	NARRATIVE	What three core qualities do others appreciate most in you or make you quietly proud?	\N	\N
F3_STORY_03	Form3_Davranis	Yaşam Anlatısı		Eğer sihirli bir değneğiniz olsaydı kendinizde değiştirmek veya geliştirmek isteyeceğiniz üç şey ne olurdu?	OpenText		0	\N	1	\N	35	NARRATIVE	If you had a magic wand what three things would you change or improve about yourself?	\N	\N
F3_STORY_05	Form3_Davranis	Yaşam Anlatısı		Geçmişe baktığınızda hatırladığınız en kötü anılar neler (en çok üç adet)?	OpenText		0	\N	1	\N	37	NARRATIVE	What are your worst memories from the past (up to three)?	\N	\N
F3_SOMATIC_02	Form3_Davranis	Bedensel Farkındalık	StressSomatization	Stres veya kaygı hissettiğinizde, bu duyguyu vücudunuzun en çok neresinde fark edersiniz? (En fazla 3 tane seçin)	MultiSelect3	Omuzlarımda/Boynumda gerginlik|Midemde/Karnımda bir düğüm|Göğsümde sıkışma|Çenemi sıkma|Kalp çarpıntısı|Ellerde terleme|Baş ağrısı|Nefes darlığı	0	\N	1	\N	\N	SOMATIC_AWARENESS	When you feel stress or anxiety, where in your body do you notice this feeling most? (Select up to 3)	Tension in my shoulders/neck|A knot in my stomach/belly|Tightness in my chest|Jaw clenching|Heart palpitations|Sweaty hands|Headache|Shortness of breath	\N
F2_MBTI_01	Form2_Kisilik	Bilişsel Tercih	E-I	Yoğun bir haftanın ardından kendinizi nasıl şarj edersiniz?	SingleChoice	A) Arkadaşlarımla buluşarak veya sosyal bir etkinliğe katılarak enerji toplarım|B) Yalnız kalarak kitap okuyarak veya sessiz bir ortamda düşünerek enerji toplarım	0	\N	1	\N	11	MBTI	How do you recharge after an intense week?	A) I gain energy by meeting with friends or attending social events|B) I gain energy by being alone reading or thinking in a quiet environment	\N
F2_MBTI_02	Form2_Kisilik	Bilişsel Tercih	E-I	Bir sosyal etkinlikte veya partide genellikle...	SingleChoice	A) Birçok farklı insanla sohbet eder ortamın merkezinde yer alırım|B) Bir veya iki kişiyle derin ve anlamlı bir sohbet kurmayı tercih ederim	0	\N	1	\N	12	MBTI	At a social event or party you usually...	A) Chat with many different people and be at the center|B) Prefer deep and meaningful conversations with one or two people	\N
F2_MBTI_18	Form2_Kisilik	Bilişsel Tercih	J-P	Sizi daha iyi tanımlayan kelime hangisi?	SingleChoice	A) Düzenli|B) Esnek	0	\N	1	\N	28	MBTI	Which word describes you better?	A) Organized|B) Flexible	\N
F3_DAILY_04	Form3_Davranis	Günlük Check-In	KeyEvent	Bugün seni en çok etkileyen (olumlu veya olumsuz) olay neydi? (Tek cümle ile)	OpenText		0	\N	1	\N	\N	DYNAMIC_TRACKING	What was the most impactful event (positive or negative) for you today? (In one sentence)	\N	\N
F1_AGE	Form1_Tanisalim	Demografik		Yaşınız	Number		0	\N	1	\N	1	DEMOGRAPHIC	Your age	\N	\N
F1_GENDER	Form1_Tanisalim	Demografik		Cinsiyetiniz	SingleChoice	Erkek|Kadın|Belirtmek İstemiyorum|Diğer	0	\N	1	\N	2	DEMOGRAPHIC	Your gender	Male|Female|Prefer not to say|Other	\N
F1_RELATIONSHIP	Form1_Tanisalim	Demografik		İlişki Durumunuz	SingleChoice	Bekâr|İlişkisi var|Evli|Boşanmış|Diğer	0	\N	1	\N	3	DEMOGRAPHIC	Relationship status	Single|In a relationship|Married|Divorced|Other	\N
F1_EDUCATION	Form1_Tanisalim	Demografik		En Yüksek Eğitim Seviyeniz	SingleChoice	İlköğretim|Lise|Üniversite|Yüksek Lisans|Doktora	0	\N	1	\N	4	DEMOGRAPHIC	Highest education level	Primary|High School|University|Master's|PhD	\N
F1_OCCUPATION	Form1_Tanisalim	Demografik		Mesleğiniz / Çalışma Durumunuz	OpenText		0	\N	1	\N	5	DEMOGRAPHIC	Your occupation/work status	\N	\N
F3_FTP_01	Form3_Davranis	Gelecek Perspektifi		Geleceğime baktığımda, önümde uzanan fırsatlarla dolu uzun bir yol görüyorum.	Scale5	1 - Kesinlikle katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Kesinlikle katılıyorum	0	\N	1	\N	\N	FTP	When I look at my future, I see a long road ahead filled with opportunities.	1 - Strongly disagree|2 - Disagree|3 - Neutral|4 - Agree|5 - Strongly agree	\N
F3_FTP_02	Form3_Davranis	Gelecek Perspektifi		Bugün yaptığım seçimlerin, 10 yıl sonraki hayatımı derinden etkileyeceğinin farkındayım.	Scale5	1 - Kesinlikle katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Kesinlikle katılıyorum	0	\N	1	\N	\N	FTP	I am aware that the choices I make today will deeply affect my life 10 years from now.	1 - Strongly disagree|2 - Disagree|3 - Neutral|4 - Agree|5 - Strongly agree	\N
F3_FTP_03	Form3_Davranis	Gelecek Perspektifi		Gelecek hakkında düşünmek bana genellikle endişe yerine heyecan ve umut verir.	Scale5	1 - Kesinlikle katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Kesinlikle katılıyorum	0	\N	1	\N	\N	FTP	Thinking about the future usually gives me excitement and hope rather than worry.	1 - Strongly disagree|2 - Disagree|3 - Neutral|4 - Agree|5 - Strongly agree	\N
F1_FOCUS_AREAS	Form1_Tanisalim	Hayata Bakış		Şu anda hayatınızdaki temel odak alanlarınız hangileri? (En fazla 3 tane seçin)	MultiSelect3	Kariyer/İş|Aile|Romantik İlişki|Arkadaşlar/Sosyal Hayat|Kişisel Gelişim|Fiziksel Sağlık|Ruhsal Sağlık|Finansal Durum|Hobiler	0	\N	1	\N	8	DEMOGRAPHIC	What are your main focus areas in life right now? (Select up to 3)	Career/Work|Family|Romantic Relationship|Friends/Social Life|Personal Development|Physical Health|Mental Health|Financial Status|Hobbies	\N
F1_LIFE_SATISFACTION	Form1_Tanisalim	Hayata Bakış		Genel olarak hayatınızdan ne kadar memnunsunuz? (1: Hiç memnun değilim - 10: Son derece memnunum)	Scale10		0	\N	1	\N	6	SITUATIONAL	How satisfied are you with your life in general? (1-10)	\N	\N
F1_PHYSICAL_ACTIVITY	Form1_Tanisalim	Enerji ve Alışkanlık		Haftalık fiziksel aktivite seviyeniz nedir?	SingleChoice	Hareketsiz|Düşük (Haftada 1-2 gün hafif egzersiz)|Orta (Haftada 3-4 gün)|Yüksek (Haftada 5+ gün)	0	\N	1	\N	12	LIFESTYLE	What is your weekly physical activity level?	Sedentary|Low (1-2 days light exercise)|Medium (3-4 days)|High (5+ days)	\N
F1_ENERGY_LEVEL	Form1_Tanisalim	Enerji ve Alışkanlık		Gün içindeki genel enerji seviyenizi nasıl puanlarsınız? (1: Çok Düşük - 10: Çok Yüksek)	Scale10		0	\N	1	\N	13	LIFESTYLE	How would you rate your general energy level during the day? (1-10)	\N	\N
F3_DAILY_01	Form3_Davranis	Günlük Check-In	Mood	Bugünkü genel ruh halini 1'den 10'a kadar nasıl puanlarsın?	Scale10	1|2|3|4|5|6|7|8|9|10	0	\N	1	1 - Çok kötü\n6 - Normal\n10 - Mükemmel	\N	DYNAMIC_TRACKING	How would you rate your overall mood today from 1 to 10?	1|2|3|4|5|6|7|8|9|10	\N
F1_BIGGEST_CHALLENGE	Form1_Tanisalim	Hayata Bakış		Şu anda karşılaştığınız en büyük zorluk nedir?	OpenText		0	\N	1	\N	9	SITUATIONAL	What is the biggest challenge you're facing right now?	\N	\N
F1_YEARLY_GOAL	Form1_Tanisalim	Hayata Bakış		Önümüzdeki bir yıl içinde ulaşmak istediğiniz en önemli hedef nedir?	OpenText		0	\N	1	\N	10	LIFE_VIEW	What is your most important goal for the next year?	\N	\N
F3_COPING_MECHANISMS	Form3_Davranis	Başa Çıkma Mekanizmaları		Zorlu duygularla (stres can sıkıntısı yalnızlık yetersizlik) başa çıkmak için aşağıdaki yöntemlerden hangilerine NORMALDEN DAHA SIK başvurduğunuzu düşünüyorsunuz? (Lütfen dürüstçe işaretleyin)	MultipleChoice	Alkol veya reçetesiz/yasa dışı madde kullanımı|Aşırı veya tıkınırcasına yemek yeme|Kontrolsüz para harcama veya kumar|Sosyal medya oyun veya internette aşırı zaman geçirme|Porno veya kompulsif cinsel davranışlar|Kendini işe aşırı verme (Workaholism)|Yukarıdakilerden hiçbiri bu alanda belirgin bir sorunum olduğunu düşünmüyorum	0	\N	1	\N	61	ADDICTIVE_PATTERNS	Which of the following methods do you think you resort to MORE FREQUENTLY THAN NORMAL to cope with difficult emotions (stress boredom loneliness inadequacy)? (Please mark honestly)	Alcohol or non-prescription/illegal substance use|Excessive or binge eating|Uncontrolled spending or gambling|Excessive time on social media games or internet|Porn or compulsive sexual behaviors|Excessive work commitment (Workaholism)|None of the above I don't think I have a significant problem in this area	\N
F3_SABOTAGE_PATTERNS	Form3_Davranis	Kendini Sabotaj		Belirlediğiniz hedeflere (kariyer ilişki sağlık vb.) ulaşmanızı engelleyen ve tekrar eden alışkanlıklarınız olduğunu fark ediyor musunuz?	MultipleChoice	İşi Erteleme ve Sorumluluktan Kaçınma|Dürtüsel Kararlar (Para harcama yeme internet vb.)|Aşırı Mükemmeliyetçilik (Başlamayı veya bitirmeyi engeller)|Negatif İç Ses ve Kendini Sürekli Eleştirme|Sosyal İlişkileri Sabote Etme (Tartışma çıkarma insanları uzaklaştırma)|Gerekli Riskleri Almaktan Korkma|Hayır, böyle alışkanlıklarım yok	0	\N	1	\N	60	SELF_SABOTAGE	In which areas do these blocking behaviors manifest most? (Select the most appropriate ones)	Procrastination and Avoiding Responsibility|Impulsive Decisions (Spending eating internet etc.)|Excessive Perfectionism (Prevents starting or finishing)|Negative Inner Voice and Constant Self-Criticism|Sabotaging Social Relationships (Starting arguments pushing people away)|Fear of Taking Necessary Risks	\N
F3_MEANING_01	Form3_Davranis	Anlam ve Amaç		Hayatımda beni aşan ve uğruna yaşamaya değer bir amaç veya misyon olduğunu hissederim.	Scale5	1 - Kesinlikle katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Kesinlikle katılıyorum	0	\N	1	\N	\N	LOGOTHERAPY	I feel there is a purpose or mission in my life that transcends me and is worth living for.	1 - Strongly disagree|2 - Disagree|3 - Neutral|4 - Agree|5 - Strongly agree	\N
F3_MEANING_02	Form3_Davranis	Anlam ve Amaç		Zorluklarla karşılaştığımda bile, yaşadıklarımda bir anlam bulabilirim.	Scale5	1 - Kesinlikle katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Kesinlikle katılıyorum	0	\N	1	\N	\N	LOGOTHERAPY	Even when I face difficulties, I can find meaning in my experiences.	1 - Strongly disagree|2 - Disagree|3 - Neutral|4 - Agree|5 - Strongly agree	\N
F3_MEANING_03	Form3_Davranis	Anlam ve Amaç		Yaptığım işlerin ve yaşadığım hayatın bir bütün olarak anlamlı ve değerli olduğuna inanıyorum.	Scale5	1 - Kesinlikle katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Kesinlikle katılıyorum	0	\N	1	\N	\N	LOGOTHERAPY	I believe that my work and life as a whole are meaningful and valuable.	1 - Strongly disagree|2 - Disagree|3 - Neutral|4 - Agree|5 - Strongly agree	\N
F2_MBTI_11	Form2_Kisilik	Bilişsel Tercih	T-F	Önemli bir karar verirken ağır basan taraf nedir?	SingleChoice	A) Mantıksal analiz objektif kriterler ve tutarlılık|B) Kararın insanları nasıl etkileyeceği kişisel değerlerim ve genel uyum	0	\N	1	\N	21	MBTI	What weighs more when making an important decision?	A) Logical analysis objective criteria and consistency|B) How the decision will affect people my personal values and overall harmony	\N
F2_MBTI_16	Form2_Kisilik	Bilişsel Tercih	J-P	Hafta sonu planlarınız genellikle nasıldır?	SingleChoice	A) Genellikle ne yapacağıma önceden karar veririm ve bir plana sadık kalmayı severim|B) Plan yapmaktan kaçınır o an canım ne isterse onu yapmayı ve spontane olmayı tercih ederim	0	\N	1	\N	26	MBTI	What are your weekend plans usually like?	A) I usually decide beforehand and like to stick to a plan|B) I avoid making plans preferring to be spontaneous	\N
F2_MBTI_17	Form2_Kisilik	Bilişsel Tercih	J-P	Bir işi yaparken kendinizi nasıl daha iyi hissedersiniz?	SingleChoice	A) İşi tamamlayıp listemden bir maddeyi daha çizdiğimde|B) Henüz seçenekler açıkken ve işin gidişatını değiştirebilecek esnekliğe sahipken	0	\N	1	\N	27	MBTI	How do you feel better when doing a job?	A) When I complete the job and cross another item off my list|B) When options are still open and I have flexibility to change the course	\N
F2_MBTI_03	Form2_Kisilik	Bilişsel Tercih	E-I	Bir proje üzerinde çalışırken...	SingleChoice	A) Fikirlerimi bir grupla tartışarak ve beyin fırtınası yaparak geliştirmeyi severim|B) Önce kendi başıma düşünüp fikirlerimi netleştirmeyi tercih ederim	0	\N	1	\N	13	MBTI	When working on a project...	A) I like developing ideas by discussing and brainstorming with a group|B) I prefer thinking on my own first and clarifying my ideas	\N
F2_MBTI_04	Form2_Kisilik	Bilişsel Tercih	E-I	İlgi odağı olmak sizi nasıl hissettirir?	SingleChoice	A) Genellikle rahatsız olmam hatta bazen bundan keyif alabilirim|B) Beni gergin ve rahatsız hissettirir genellikle bundan kaçınırım	0	\N	1	\N	14	MBTI	How does being the center of attention make you feel?	A) I usually don't feel uncomfortable sometimes even enjoy it|B) It makes me feel tense and uncomfortable I usually avoid it	\N
F1_STRESS_LEVEL	Form1_Tanisalim	Hayata Bakış		Şu anki stres seviyenizi nasıl tanımlarsınız? (1: Neredeyse hiç stres yok - 10: Aşırı stresli)	Scale10	1|2|3|4|5|6|7|8|9|10	0	\N	1	1 - Neredeyse hiç stres yok\n5 - Orta düzey stres\n10 - Aşırı stresli	7	SITUATIONAL	How would you describe your current stress level? (1-10)	\N	\N
F2_MBTI_05	Form2_Kisilik	Bilişsel Tercih	E-I	Yeni tanıştığınız insanlara karşı tavrınız nasıldır?	SingleChoice	A) Genellikle konuşmayı ben başlatırım ve kendim hakkında kolayca bilgi paylaşırım|B) Genellikle karşımdakinin soru sormasını bekler daha çok dinleyici konumunda kalırım	0	\N	1	\N	15	MBTI	Your attitude towards people you just met?	A) I usually start the conversation and easily share information about myself|B) I usually wait for others to ask questions and remain more in listener position	\N
F2_MBTI_19	Form2_Kisilik	Bilişsel Tercih	J-P	Son teslim tarihleri (deadline) hakkında ne düşünürsünüz?	SingleChoice	A) İşleri zamanında bitirmemi sağlayan faydalı ve motive edici araçlardır|B) Yaratıcılığı ve esnekliği kısıtlayan gereksiz birer stres kaynağıdır	0	\N	1	\N	29	MBTI	What do you think about deadlines?	A) They are useful and motivating tools that help me finish work on time|B) They are unnecessary sources of stress that restrict creativity and flexibility	\N
F2_MBTI_20	Form2_Kisilik	Bilişsel Tercih	J-P	Bir seyahate çıkarken...	SingleChoice	A) Gideceğim yerleri kalacağım oteli ve yapacağım aktiviteleri önceden planlamayı ve organize etmeyi severim|B) Sadece genel bir rota belirler geri kalan detayları yolculuk sırasında akışına bırakırım	0	\N	1	\N	30	MBTI	When going on a trip...	A) I like to plan and organize places hotel and activities in advance|B) I just set a general route leaving details to flow during the journey	\N
F3_FTP_04	Form3_Davranis	Gelecek Perspektifi		Hedeflerim bana çok uzak ve ulaşılmaz geliyor.	Scale5	1 - Kesinlikle katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Kesinlikle katılıyorum	1	\N	1	\N	\N	FTP	My goals feel very distant and unreachable to me.	1 - Strongly disagree|2 - Disagree|3 - Neutral|4 - Agree|5 - Strongly agree	\N
F3_STORY_04	Form3_Davranis	Yaşam Anlatısı		Hayatınızdaki en mutlu anlarınızı (en çok üç adet) anlatır mısınız? O anı bu kadar özel ve neşeli kılan neydi?	OpenText		0	\N	1	\N	36	NARRATIVE	Describe your happiest moments (up to three). What made them so special and joyful?	\N	\N
F3_STORY_06	Form3_Davranis	Yaşam Anlatısı		Geriye dönüp baktığınızda önemli bir pişmanlığınızı anlatın. Geri dönebilseydiniz neyi farklı yapardınız ve bu deneyimden ne öğrendiniz?	OpenText		0	\N	1	\N	38	NARRATIVE	Describe an important regret. What would you do differently and what did you learn?	\N	\N
F3_STORY_07	Form3_Davranis	Yaşam Anlatısı		En çok gurur duyduğunuz bir başarıyı veya kararı anlatın. Bu an en iyi halinizdeyken kim olduğunuz hakkında ne söylüyor?	OpenText		0	\N	1	\N	39	NARRATIVE	Describe an achievement or decision you're most proud of. What does it say about who you are at your best?	\N	\N
F3_STORY_08	Form3_Davranis	Yaşam Anlatısı		Hayatınızın bir sonraki bölümünü düşünürken en büyük umudunuz nedir? Ve en büyük korkunuz nedir?	OpenText		0	\N	1	\N	40	NARRATIVE	When thinking about the next chapter of your life what is your greatest hope? And your greatest fear?	\N	\N
S3_EMOTION_REG_3	Form3_Davranis	Duygu Düzenleme	Reappraisal	Olumsuz bir olay yaşadığımda, genellikle bundan öğrenebileceğim bir ders veya olumlu bir yan bulmaya çalışırım.	Likert5	1 - Hiç Katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Tamamen Katılıyorum	0	\N	1	\N	\N	EMOTION_REGULATION	\N	\N	\N
S3_CONFLICT_1	Form3_Davranis	Çatışma Yönetimi	TKI	Bir takım projesinde, üyelerden biri kendi payına düşen işi sürekli aksatıyor. Tepkiniz ne olur?	MultipleChoice	A) Durumun önemini ve beklentileri net bir şekilde ortaya koyar, görevini yapmasını sağlarım.|B) Herkesin endişelerini ve sorunun kökenini anlamak için bir toplantı düzenler, hep birlikte kalıcı bir çözüm bulmaya çalışırım.|C) Her iki tarafın da biraz fedakarlık yapacağı bir orta yol buluruz; belki bazı görevlerini ben üstlenirim, o da kalanları kesinlikle yapar.|D) Şimdilik konuyu gündeme getirmez, belki durumun kendiliğinden düzeleceğini umarım veya çatışmadan kaçınırım.|E) Takım arkadaşımın stresli olabileceğini düşünür, ona yardımcı olmak için elimden geleni yapar ve uyumu korumaya odaklanırım.	0	\N	1	\N	\N	CONFLICT_STYLE	\N	\N	\N
S3_CONFLICT_2	Form3_Davranis	Çatışma Yönetimi	TKI	Partnerinizle tatil planı yapıyorsunuz. Siz dağa gitmek isterken, o denize gitmek istiyor.	MultipleChoice	A) Dağın neden daha iyi bir seçenek olduğuna dair mantıklı argümanlar sunar ve onu ikna etmeye çalışırım.|B) İkimizin de tatilden beklentilerini masaya yatırır, her iki beklentiyi de karşılayacak yaratıcı bir alternatif (belki hem denizi hem dağı olan bir yer) ararız.|C) Bu sefer denize gidelim, bir sonraki sefere mutlaka dağa gideriz diyerek anlaşırız.|D) Tatil konusunu bir süreliğine rafa kaldırırım, tartışmanın büyümesini istemem.|E) Onun mutluluğu benim için daha önemli, planlarımı değiştirip onun istediği yere giderim.	0	\N	1	\N	\N	CONFLICT_STYLE	\N	\N	\N
S3_EMOTION_REG_1	Form3_Davranis	Duygu Düzenleme	Reappraisal	Stresli bir durumla karşılaştığımda, olaya farklı ve daha olumlu bir açıdan bakmaya çalışırım.	Likert5	1 - Hiç Katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Tamamen Katılıyorum	0	\N	1	\N	\N	EMOTION_REGULATION	\N	\N	\N
S3_EMOTION_REG_2	Form3_Davranis	Duygu Düzenleme	Reappraisal	Duygularımı kontrol etmem gerektiğinde, içinde bulunduğum durum hakkındaki düşüncelerimi değiştiririm.	Likert5	1 - Hiç Katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Tamamen Katılıyorum	0	\N	1	\N	\N	EMOTION_REGULATION	\N	\N	\N
S3_EMOTION_REG_4	Form3_Davranis	Duygu Düzenleme	Suppression	Duygularımı hissettiğimde, genellikle onları kendime saklarım.	Likert5	1 - Hiç Katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Tamamen Katılıyorum	0	\N	1	\N	\N	EMOTION_REGULATION	\N	\N	\N
S3_EMOTION_REG_5	Form3_Davranis	Duygu Düzenleme	Suppression	Olumlu veya olumsuz duygular yaşadığımda, onları dışarıya göstermemeye özen gösteririm.	Likert5	1 - Hiç Katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Tamamen Katılıyorum	0	\N	1	\N	\N	EMOTION_REGULATION	\N	\N	\N
S3_EMOTION_REG_6	Form3_Davranis	Duygu Düzenleme	Suppression	İnsanlar üzgün veya gergin olduğumu anlamasın diye duygularımı kontrol altında tutarım.	Likert5	1 - Hiç Katılmıyorum|2 - Katılmıyorum|3 - Kararsızım|4 - Katılıyorum|5 - Tamamen Katılıyorum	0	\N	1	\N	\N	EMOTION_REGULATION	\N	\N	\N
S3_EMPATHY_1	Form3_Davranis	Empati	Empathic_Concern	Zor durumda olan birini gördüğümde, ona karşı koruyucu ve şefkatli hisler duyarım.	Likert5	1 - Beni Hiç Tanımlamıyor|2 - Beni Az Tanımlıyor|3 - Kararsızım|4 - Beni Tanımlıyor|5 - Beni Tamamen Tanımlıyor	0	\N	1	\N	\N	EMPATHY	\N	\N	\N
S3_EMPATHY_2	Form3_Davranis	Empati	Empathic_Concern	Başkalarının talihsizlikleri beni derinden etkiler.	Likert5	1 - Beni Hiç Tanımlamıyor|2 - Beni Az Tanımlıyor|3 - Kararsızım|4 - Beni Tanımlıyor|5 - Beni Tamamen Tanımlıyor	0	\N	1	\N	\N	EMPATHY	\N	\N	\N
S3_EMPATHY_3	Form3_Davranis	Empati	Empathic_Concern	Bir arkadaşım bir sorun yaşadığında, onun adına gerçekten üzülürüm.	Likert5	1 - Beni Hiç Tanımlamıyor|2 - Beni Az Tanımlıyor|3 - Kararsızım|4 - Beni Tanımlıyor|5 - Beni Tamamen Tanımlıyor	0	\N	1	\N	\N	EMPATHY	\N	\N	\N
S3_EMPATHY_4	Form3_Davranis	Empati	Perspective_Taking	Bir tartışmada, karşımdakinin haklı olabileceği noktaları görmeye çalışırım.	Likert5	1 - Beni Hiç Tanımlamıyor|2 - Beni Az Tanımlıyor|3 - Kararsızım|4 - Beni Tanımlıyor|5 - Beni Tamamen Tanımlıyor	0	\N	1	\N	\N	EMPATHY	\N	\N	\N
S3_EMPATHY_5	Form3_Davranis	Empati	Perspective_Taking	Her hikayenin iki yüzü olduğuna inanırım ve karar vermeden önce her iki tarafı da anlamaya çalışırım.	Likert5	1 - Beni Hiç Tanımlamıyor|2 - Beni Az Tanımlıyor|3 - Kararsızım|4 - Beni Tanımlıyor|5 - Beni Tamamen Tanımlıyor	0	\N	1	\N	\N	EMPATHY	\N	\N	\N
S3_EMPATHY_6	Form3_Davranis	Empati	Perspective_Taking	İnsanların davranışlarını anlamak için kendimi onların yerine koymakta zorlanmam.	Likert5	1 - Beni Hiç Tanımlamıyor|2 - Beni Az Tanımlıyor|3 - Kararsızım|4 - Beni Tanımlıyor|5 - Beni Tamamen Tanımlıyor	1	\N	1	\N	\N	EMPATHY	\N	\N	\N
F1_SLEEP_QUALITY	Form1_Tanisalim	Enerji ve Alışkanlık		Genel olarak uyku kalitenizi nasıl puanlarsınız?	Scale10	1|2|3|4|5|6|7|8|9|10	0	\N	1	1 - Çok kötü uyku\n6 - Ne çok iyi ne çok kötü uyku\n10 - Mükemmel ve derin uyku	11	ENERGY_HABITS	How would you rate your sleep quality? (1-10)	\N	\N
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
11eaef8f-1882-4534-a102-3e59a6d4a038	ebe6eee2-01ae-4753-9737-0983b0330880	d97fa5cb-dec8-42bc-ba99-8324f1b3e287	2025-08	2	14	0	0	0	16.4790	0.00	2025-08-29 21:00:09.312451	2025-08-29 22:20:44.844829
\.


--
-- Data for Name: payg_pricing; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payg_pricing (id, service_type, price_usd, is_active, created_at, updated_at) FROM stdin;
payg_coaching_100k	coaching_100k	8.00	t	2025-08-19 18:54:08.407814	2025-08-30 01:53:15.840062
payg_coaching_500k	coaching_500k	15.00	t	2025-08-19 18:54:08.407814	2025-08-30 01:53:15.861883
payg_new_person	new_person	3.00	t	2025-08-19 18:54:08.407814	2025-08-30 01:53:15.880662
payg_relationship	relationship	3.00	t	2025-08-19 18:54:08.407814	2025-08-30 01:53:15.899102
payg_relationship_re	relationship_reanalysis	2.00	t	2025-08-19 18:54:08.407814	2025-08-30 01:53:15.920395
payg_person_re	same_person_reanalysis	2.00	t	2025-08-19 18:54:08.407814	2025-08-30 01:53:15.93916
payg_self	self_analysis	5.50	t	2025-08-19 18:54:08.407814	2025-08-30 01:53:15.957926
payg_self_re	self_reanalysis	3.00	t	2025-08-19 18:54:08.407814	2025-08-30 01:53:15.976064
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

COPY public.subscription_plans (id, name, self_analysis_limit, self_reanalysis_limit, other_analysis_limit, relationship_analysis_limit, coaching_tokens_limit, price_usd, is_active, created_at, updated_at, total_analysis_credits) FROM stdin;
free	Ücretsiz	1	1	1	1	15000	0.00	t	2025-08-30 01:21:52.088619	2025-08-30 03:24:39.672227	1
standard	Standart	1	15	15	15	500000	20.00	t	2025-08-19 18:54:08.406793	2025-08-30 03:24:39.691184	15
extra	Extra	1	30	30	30	2000000	50.00	t	2025-08-19 18:54:08.406793	2025-08-30 03:24:39.709531	30
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
-- Data for Name: token_packages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.token_packages (id, package_size, token_amount, price_usd, is_active, created_at, updated_at) FROM stdin;
token_250k	250K	250000	8.00	t	2025-08-30 01:54:30.717435	2025-08-30 01:57:36.787898
token_500k	500K	500000	15.00	t	2025-08-30 01:54:30.717435	2025-08-30 01:57:36.812087
token_1m	1M	1000000	25.00	t	2025-08-30 01:54:30.717435	2025-08-30 01:57:36.834647
token_5m	5M	5000000	100.00	t	2025-08-30 01:54:30.717435	2025-08-30 01:57:36.860015
\.


--
-- Data for Name: usage_tracking; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usage_tracking (id, user_id, service_type, target_id, is_reanalysis, tokens_used, input_tokens, output_tokens, cost_usd, price_charged_usd, subscription_id, created_at) FROM stdin;
c3563adb-da6d-446c-8c32-8b328780099d	5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	self_analysis	self	f	13371	4761	5331	0.4627	5.00	\N	2025-08-20 23:00:49.638886
89384bd5-2192-4d4f-ab4d-039d0e1a55bf	5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	self_analysis	self	t	12614	4757	5169	0.4529	3.00	\N	2025-08-20 23:04:20.019725
777783c4-ab17-4d14-953a-a03e1b1475d4	2a1881bf-51c8-4726-ad0e-4206633e351d	self_analysis	self	f	15756	4796	4474	0.4123	5.00	\N	2025-08-20 23:10:18.603906
a5938d11-5b21-44ba-80dc-714fe5eddb52	f55dfb24-6a6e-495d-86c7-897a73ffcb88	self_analysis	self	f	8643	3976	2733	0.2833	5.00	\N	2025-08-20 23:11:36.872418
f0a8156c-b8ac-4e8c-835a-5d8a115a7197	ebe6eee2-01ae-4753-9737-0983b0330880	self_analysis	self	f	33161	22318	5708	1.0120	0.00	d97fa5cb-dec8-42bc-ba99-8324f1b3e287	2025-08-29 21:00:09.312451
0e9806b9-7efa-4893-a8bd-1123c4bf18ea	ebe6eee2-01ae-4753-9737-0983b0330880	self_analysis	self	t	34810	22318	5946	1.0263	0.00	d97fa5cb-dec8-42bc-ba99-8324f1b3e287	2025-08-29 21:08:08.247818
89c33fd7-54ef-4b6b-8f3f-6bcdf421883e	ebe6eee2-01ae-4753-9737-0983b0330880	self_analysis	self	t	37171	22331	6503	1.0601	0.00	d97fa5cb-dec8-42bc-ba99-8324f1b3e287	2025-08-29 21:19:17.135363
311e4261-a554-4c60-9768-905c0ae410ce	ebe6eee2-01ae-4753-9737-0983b0330880	self_analysis	self	t	35029	22331	6069	1.0341	0.00	d97fa5cb-dec8-42bc-ba99-8324f1b3e287	2025-08-29 21:42:04.759695
c1e5c630-7716-4bac-9dc1-adfcf7a9687e	ebe6eee2-01ae-4753-9737-0983b0330880	self_analysis	self	t	32956	22331	5741	1.0144	0.00	d97fa5cb-dec8-42bc-ba99-8324f1b3e287	2025-08-29 21:50:45.97519
fa23dc43-282f-411a-b1a4-08bdab281230	ebe6eee2-01ae-4753-9737-0983b0330880	self_analysis	self	t	33215	22331	6568	1.0640	0.00	d97fa5cb-dec8-42bc-ba99-8324f1b3e287	2025-08-29 22:05:56.244115
38b4bfd1-c855-41ee-8667-05d238dddef7	ebe6eee2-01ae-4753-9737-0983b0330880	self_analysis	self	t	33567	22331	5820	1.0191	0.00	d97fa5cb-dec8-42bc-ba99-8324f1b3e287	2025-08-29 22:10:43.524305
2ef4b66b-de0c-4c17-8669-ec140f955041	ebe6eee2-01ae-4753-9737-0983b0330880	self_analysis	self	t	34410	22331	5660	1.0095	0.00	d97fa5cb-dec8-42bc-ba99-8324f1b3e287	2025-08-29 22:20:44.844829
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

COPY public.user_subscriptions (id, user_id, plan_id, status, billing_cycle, start_date, end_date, created_at, updated_at, credits_used, credits_remaining, is_primary, iap_transaction_id, coupon_id) FROM stdin;
a2d2989e-abc7-4ff9-8706-c094d8c72b3b	ebe6eee2-01ae-4753-9737-0983b0330880	free	active	monthly	2025-08-30 03:56:30.482385	2025-09-29 03:56:30.482385	2025-08-30 03:56:30.482385	2025-08-30 03:56:30.482385	{}	{"self_analysis": 1, "other_analysis": 0, "coaching_tokens": 0, "self_reanalysis": 0, "relationship_analysis": 0}	f	\N	\N
4016267e-30f1-477e-a085-6f194c89f19c	ebe6eee2-01ae-4753-9737-0983b0330880	free	active	monthly	2025-08-30 04:01:21.361063	2025-09-30 04:01:21.36	2025-08-30 04:01:21.361063	2025-08-30 04:01:21.361063	{}	{"other_analysis": 1, "coaching_tokens": 15000, "self_reanalysis": 1, "relationship_analysis": 1}	f	\N	\N
1b76c40f-eda7-4c3c-89ee-81ef4152d053	ebe6eee2-01ae-4753-9737-0983b0330880	free	active	monthly	2025-08-30 04:13:08.967601	2025-09-30 04:13:08.967	2025-08-30 04:13:08.967601	2025-08-30 04:13:08.967601	{}	{"other_analysis": 1, "coaching_tokens": 15000, "self_reanalysis": 1, "relationship_analysis": 1}	f	\N	\N
467634d9-6fa0-466b-b3aa-536392262e75	d3fde6ba-27df-4240-a304-322dccf7ad06	standard	active	monthly	2025-08-24 20:57:12.859699	2025-09-23 20:57:12.859699	2025-08-24 20:57:12.859699	2025-08-24 20:57:12.859699	{}	{"self_analysis": 1, "other_analysis": 8, "coaching_tokens": 15000, "self_reanalysis": 2, "relationship_analysis": 8}	t	\N	\N
9deca9b0-ccf0-4b51-8f76-25d76528636d	d87e115c-0d54-4bcc-9c17-773c43423f09	standard	active	monthly	2025-08-24 23:59:32.132867	2025-09-23 23:59:32.132867	2025-08-24 23:59:32.132867	2025-08-24 23:59:32.132867	{}	{"self_analysis": 1, "other_analysis": 8, "coaching_tokens": 15000, "self_reanalysis": 2, "relationship_analysis": 8}	t	\N	\N
4b8b9bc8-56a9-4ef6-b2f6-2af014a588b1	d3fde6ba-27df-4240-a304-322dccf7ad06	standard	active	monthly	2025-08-25 00:17:43.142185	2025-09-25 00:17:43.14	2025-08-25 00:17:43.142185	2025-08-25 00:17:43.142185	{}	{"self_analysis": 1, "other_analysis": 8, "coaching_tokens": 15000, "self_reanalysis": 2, "relationship_analysis": 8}	f	\N	a03e9436-aa9d-44bd-a676-6cd89f6ecfc7
e3c33a0e-90f0-4506-9e84-bdf3c12dc437	9fa8e776-9698-4c17-8c08-09126d5a2b85	standard	active	monthly	2025-08-25 00:35:29.05974	2025-09-29 00:28:18.164644	2025-08-25 00:35:29.05974	2025-08-25 00:35:29.05974	{}	{"self_analysis": 1, "other_analysis": 8, "coaching_tokens": 15000, "self_reanalysis": 2, "relationship_analysis": 8}	t	\N	\N
bc822d05-6b7d-4d42-a7da-680c386882c7	ebe6eee2-01ae-4753-9737-0983b0330880	standard	cancelled	monthly	2025-08-19 22:19:40.282202	2025-08-29 23:59:59	2025-08-19 22:19:40.282202	2025-08-30 03:24:15.687043	{}	{"other_analysis": 8, "coaching_tokens": 15000, "self_reanalysis": 2, "relationship_analysis": 8}	f	\N	\N
983fadf4-f8cb-4f87-a326-9cb5dddd29b4	ebe6eee2-01ae-4753-9737-0983b0330880	standard	active	monthly	2025-08-23 00:12:18.221856	2025-08-29 23:59:59	2025-08-23 00:12:18.221856	2025-08-23 00:12:18.221856	{}	{"other_analysis": 8, "coaching_tokens": 15000, "self_reanalysis": 2, "relationship_analysis": 8}	f	\N	a03e9436-aa9d-44bd-a676-6cd89f6ecfc7
2dd37537-8a71-44aa-a22c-8722c0f9b524	ebe6eee2-01ae-4753-9737-0983b0330880	extra	cancelled	monthly	2025-08-19 22:38:45.373423	2025-08-29 23:59:59	2025-08-19 22:38:45.373423	2025-08-30 03:03:44.019525	{}	{"other_analysis": 25, "coaching_tokens": 50000, "self_reanalysis": 5, "relationship_analysis": 25}	f	\N	\N
d97fa5cb-dec8-42bc-ba99-8324f1b3e287	ebe6eee2-01ae-4753-9737-0983b0330880	standard	cancelled	monthly	2025-08-23 00:16:38.334134	2025-08-29 23:59:59	2025-08-23 00:16:38.334134	2025-08-30 03:28:23.339959	{}	{"other_analysis": 8, "coaching_tokens": 15000, "self_reanalysis": 2, "relationship_analysis": 8}	f	\N	a03e9436-aa9d-44bd-a676-6cd89f6ecfc7
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, email, locale, created_at) FROM stdin;
ebe6eee2-01ae-4753-9737-0983b0330880	test@test.com	tr	2025-08-19 20:39:47.570899+03
5c8ced7a-16bc-485e-a85d-f1d0dc81b22b	realtest@test.com	\N	2025-08-20 22:59:23.023997+03
2a1881bf-51c8-4726-ad0e-4206633e351d	test@example.com	\N	2025-08-20 23:08:29.82366+03
f55dfb24-6a6e-495d-86c7-897a73ffcb88	verify@test.com	\N	2025-08-20 23:10:50.292774+03
d3fde6ba-27df-4240-a304-322dccf7ad06	gmzsucu.gs@gmail.com	tr	2025-08-24 20:57:12.859699+03
d87e115c-0d54-4bcc-9c17-773c43423f09	niyazisucu@gmail.com	tr	2025-08-24 23:59:32.132867+03
9fa8e776-9698-4c17-8c08-09126d5a2b85	tariksucu@gmail.com	tr	2025-08-25 00:35:13.412059+03
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
-- Name: coupon_usage coupon_usage_coupon_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_coupon_id_user_id_key UNIQUE (coupon_id, user_id);


--
-- Name: coupon_usage coupon_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_pkey PRIMARY KEY (id);


--
-- Name: coupons coupons_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_code_key UNIQUE (code);


--
-- Name: coupons coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


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
-- Name: token_packages token_packages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_packages
    ADD CONSTRAINT token_packages_pkey PRIMARY KEY (id);


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
-- Name: idx_coupon_usage_coupon; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coupon_usage_coupon ON public.coupon_usage USING btree (coupon_id);


--
-- Name: idx_coupon_usage_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coupon_usage_user ON public.coupon_usage USING btree (user_id);


--
-- Name: idx_coupons_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coupons_code ON public.coupons USING btree (code);


--
-- Name: idx_coupons_valid_dates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_coupons_valid_dates ON public.coupons USING btree (valid_from, valid_until);


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
-- Name: coupon_usage coupon_usage_coupon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_coupon_id_fkey FOREIGN KEY (coupon_id) REFERENCES public.coupons(id) ON DELETE CASCADE;


--
-- Name: coupon_usage coupon_usage_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.user_subscriptions(id);


--
-- Name: coupon_usage coupon_usage_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupon_usage
    ADD CONSTRAINT coupon_usage_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: coupons coupons_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coupons
    ADD CONSTRAINT coupons_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.subscription_plans(id);


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
-- Name: user_subscriptions user_subscriptions_coupon_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_coupon_id_fkey FOREIGN KEY (coupon_id) REFERENCES public.coupons(id);


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

