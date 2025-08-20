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
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: get_user_active_subscriptions(uuid); Type: FUNCTION; Schema: public; Owner: postgres
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


ALTER FUNCTION public.get_user_active_subscriptions(p_user_id uuid) OWNER TO postgres;

--
-- Name: process_iap_renewal(uuid, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
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


ALTER FUNCTION public.process_iap_renewal(p_user_id uuid, p_transaction_id character varying, p_product_id character varying, p_platform character varying) OWNER TO postgres;

--
-- Name: update_monthly_usage(); Type: FUNCTION; Schema: public; Owner: postgres
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


ALTER FUNCTION public.update_monthly_usage() OWNER TO postgres;

--
-- Name: update_monthly_usage_summary(); Type: FUNCTION; Schema: public; Owner: postgres
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


ALTER FUNCTION public.update_monthly_usage_summary() OWNER TO postgres;

--
-- Name: update_subscription_credits(text, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
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


ALTER FUNCTION public.update_subscription_credits(p_subscription_id text, p_service_type text, p_amount integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: analysis_results; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.analysis_results OWNER TO postgres;

--
-- Name: TABLE analysis_results; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.analysis_results IS 'Stores all analysis results with status tracking';


--
-- Name: COLUMN analysis_results.status; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.analysis_results.status IS 'Current status: processing, completed, or error';


--
-- Name: COLUMN analysis_results.s0_data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.analysis_results.s0_data IS 'S0 form data (stored for retry functionality)';


--
-- Name: COLUMN analysis_results.s1_data; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.analysis_results.s1_data IS 'S1 form data (stored for retry functionality)';


--
-- Name: assessments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assessments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    person_id uuid NOT NULL,
    type text,
    version text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT assessments_type_check CHECK ((type = ANY (ARRAY['S1'::text, 'S2'::text, 'S3'::text, 'S4'::text])))
);


ALTER TABLE public.assessments OWNER TO postgres;

--
-- Name: chat_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    dyad_id uuid NOT NULL,
    metadata jsonb
);


ALTER TABLE public.chat_sessions OWNER TO postgres;

--
-- Name: dyad_scores; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.dyad_scores OWNER TO postgres;

--
-- Name: dyads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dyads (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    a_person_id uuid NOT NULL,
    b_person_id uuid NOT NULL,
    relation_type text NOT NULL
);


ALTER TABLE public.dyads OWNER TO postgres;

--
-- Name: iap_products; Type: TABLE; Schema: public; Owner: postgres
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
    CONSTRAINT iap_products_product_type_check CHECK (((product_type)::text = ANY ((ARRAY['subscription'::character varying, 'consumable'::character varying, 'non_consumable'::character varying])::text[])))
);


ALTER TABLE public.iap_products OWNER TO postgres;

--
-- Name: iap_purchases; Type: TABLE; Schema: public; Owner: postgres
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
    CONSTRAINT iap_purchases_platform_check CHECK (((platform)::text = ANY ((ARRAY['ios'::character varying, 'android'::character varying])::text[])))
);


ALTER TABLE public.iap_purchases OWNER TO postgres;

--
-- Name: items; Type: TABLE; Schema: public; Owner: postgres
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
    display_order integer
);


ALTER TABLE public.items OWNER TO postgres;

--
-- Name: language_incidents; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.language_incidents OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    session_id uuid NOT NULL,
    role text,
    content text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT messages_role_check CHECK ((role = ANY (ARRAY['user'::text, 'assistant'::text, 'system'::text])))
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: monthly_usage_summary; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.monthly_usage_summary OWNER TO postgres;

--
-- Name: payg_pricing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payg_pricing (
    id text NOT NULL,
    service_type text NOT NULL,
    price_usd numeric(10,2) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.payg_pricing OWNER TO postgres;

--
-- Name: payg_purchases; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.payg_purchases OWNER TO postgres;

--
-- Name: people; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.people OWNER TO postgres;

--
-- Name: reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reports (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    owner_user_id uuid NOT NULL,
    dyad_id uuid NOT NULL,
    markdown text,
    version text
);


ALTER TABLE public.reports OWNER TO postgres;

--
-- Name: responses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.responses (
    id bigint NOT NULL,
    assessment_id uuid NOT NULL,
    item_id text NOT NULL,
    value text NOT NULL,
    rt_ms integer
);


ALTER TABLE public.responses OWNER TO postgres;

--
-- Name: responses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.responses_id_seq OWNER TO postgres;

--
-- Name: responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.responses_id_seq OWNED BY public.responses.id;


--
-- Name: scores; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.scores OWNER TO postgres;

--
-- Name: subscription_plans; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.subscription_plans OWNER TO postgres;

--
-- Name: token_costs; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.token_costs OWNER TO postgres;

--
-- Name: usage_tracking; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.usage_tracking OWNER TO postgres;

--
-- Name: user_lifecoaching_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_lifecoaching_notes (
    user_id uuid NOT NULL,
    notes jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_lifecoaching_notes OWNER TO postgres;

--
-- Name: TABLE user_lifecoaching_notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.user_lifecoaching_notes IS 'Stores AI-generated lifecoaching context notes for each user';


--
-- Name: COLUMN user_lifecoaching_notes.notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.user_lifecoaching_notes.notes IS 'JSON data containing user insights for coaching: values, boundaries, triggers, communication style, etc.';


--
-- Name: user_subscriptions; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.user_subscriptions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email text,
    locale text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: responses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responses ALTER COLUMN id SET DEFAULT nextval('public.responses_id_seq'::regclass);


--
-- Data for Name: analysis_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.analysis_results (id, user_id, analysis_type, status, s0_data, s1_data, result_markdown, lifecoaching_notes, error_message, retry_count, created_at, completed_at, metadata) FROM stdin;
e20cd1de-ad74-4be9-b670-571401f4e552	ebe6eee2-01ae-4753-9737-0983b0330880	self	completed	{}	{}	### 1) MBTI Hypothesis (Plain-Language)\n- Your likely pattern looks most like INFP. Two nearby alternatives: ENFP, INFJ.\n- Gündelik anlamda: Yalnız kaldığınızda şarj oluyor gibi görünüyorsunuz; kalabalık yerine sakin ortamlarda daha net düşünme eğilimi var. Bilgiye yaklaşımınız fikirler, olasılıklar ve “büyük resim” odaklı; gelecekteki potansiyeli merak ediyorsunuz. Kararlarda insanların etkisi ve değerler öne çıkıyor; dili yumuşatıp ilişkisel etkileri gözetmeye yatkınsınız. Organizasyon tarafında “esneklik” ve seçenekleri bir süre açık tutma rahat geliyor; belirsizliği idare edebilme kapasitesi var.\n- Sınırda görünebilecek eksenler ve neye bakarız:\n  - I–E: Eğer uzun sosyal günlerden sonra ekstra enerji buluyor ve sürekli dış etkileşimle canlı kalıyorsanız ENFP’ye yaklaşır; tersi durumda INFP daha isabetlidir.\n  - J–P: Kapanmış kararlar, kontrol listeleri, erken planlama sizi rahatlatıyorsa INFJ’ye yaklaşır; seçenekleri açık tutmak ve akışta kalmak rahatsa INFP çizgisini destekler.\n  - T–F ve S–N: Mevcut işaretler duygu/etkiyi ve soyut fikirleri belirgin biçimde öne çıkarıyor; burada güçlü bir eğilim var.\n\n### 2) Personality Traits\n- Temperament: Genelde sakin ve iç gözlemli; değerleriniz tetiklenince hızlı ve net olabiliyorsunuz. Sabırlısınız; ama dayatılan tempoya ve yüzeyselliğe tahammülünüz düşük.\n- Strengths:\n  - Empati, derin dinleme, insana dair nüansları fark etme.\n  - Yaratıcı düşünme; olasılıkları ve anlamı birleştirme.\n  - Özgünlük ve değer tutarlılığı; güven kurmada güçlü temel.\n  - Yazılı ifade ve sembolik anlatıma yatkınlık (hikâyeleştirme).\n- Watch-outs:\n  - Erteleme ve “mükemmel olana kadar bekleme.”\n  - Çatışmadan kaçınma, sınırları geç bildirme.\n  - İdari/teknik detaylarda motivasyon düşüşü; dağınık öncelikler.\n  - Fazla uyum adına kendi ihtiyaçlarının geri planda kalması.\n- Communication style: Sıcak, diplomatik, hikâye/örnek üzerinden anlatma. Keskin veri yerine insan etkisine odaklanma; yine de kısa özet ve net istekleri takdir edersiniz.\n- Risk appetite: Orta. Değerle uyumlu yaratıcı projelerde cesur; finansal/itibar riskinde temkinli. Çıkış rampası ve destek olduğunda risk iştahı artar.\n\n### 3) Behavior Patterns\n- Crisis responses: Önce insanların iyi olduğundan emin olma, ardından sakin ve pragmatik adımlar. Aşırı gürültü ve acele baskısında içe çekilme eğilimi.\n- Decision style: İçgüdü + değer harmanı. Büyük resmi hızla görür, birkaç güvendiğiniz kişiye danışır, kesin kapatma için zamanı esnetebilirsiniz.\n- Habits & routines; micro-frictions to avoid:\n  - Yardımcı yapılarla (zaman kutuları, iki düzeyli yapılacak listesi) daha üretkensiniz.\n  - Gürültü, mikroyönetim, belirsiz talimat ve yüzeysellik “sürtünme” yaratır.\n  - Uygun: Sessiz bloklar, kısa niyet cümlesi, “şimdiki adım” netliği.\n- Pressure chain (trigger → reaction → cool-down):\n  - Saygısız üslup/acele dayatması → içe kapanma ya da kısa süreli tutum sertleşmesi → yalnız kalma, yazma/yürüyüş, bakışı yeniden çerçeveleme.\n- Safety awareness: İnsan ve ilişki etkisinde dikkatli; ancak süreç/dokümantasyonda “yeterince iyi” ile yetinip köşe kesmeye meyledebilirsiniz. Kısa kontrol listeleriyle bunu dengeleyin.\n\n### 4) Psychological Profile\n- Emotional balance: Dalgamsı; yoğun hissedip sonra derin düşünmeye çekilirsiniz. Erken uyarı: Aşırı ruminasyon, uykuya dalmada zorlanma, erteleme artışı.\n- Ego posture: Alçakgönüllü ve otantik; dış onaydan çok değer tutarlılığı ararsınız. Yine de görülme/takdir edilme ihtiyacı göz ardı edilmemeli.\n- Core motivations: Anlam, otantiklik, başkalarına fayda, yaratıcı ifade, özerklik.\n- Potential vulnerabilities + repair moves:\n  - Sınır belirsizliği → “İki cümlelik sınır” pratiği (neye evet/hayır, alternatif).\n  - Karar erteleme → 24–48 saatlik “karar penceresi” ve “yeterince iyi” kriteri.\n  - Çatışma kaçınma → “Ben-dili + tek somut istek” formatı.\n  - Dağınık odak → Günün ilk 60 dakikası derin iş, dış uyarı kapalı.\n\n### 5) Social Relations\n- Stance toward authority: Seçici. Yetkinlik ve adalete saygınız yüksek; biçimsel otorite tek başına ikna edici değil.\n- Effect on others: Sizi “düşünceli, güven verici, yaratıcı perspektif sunan” biri olarak deneyimlerler. Grup içinde sessizce dengeleyen ve fikirleri birleştiren rolü üstlenirsiniz.\n- Fast connections vs. friction:\n  - Hızlı bağ: Derin sohbet, ortak değer, yaratıcı konular.\n  - Sürtünme: Aşırı direkt ve duygusuz üslup, katı kurallar, sürekli yüksek tempo.\n\n### 6) Strategic Assessment (Ethical, Collaboration-Oriented)\n- Reliability: Değerle uyumlu sözleri tutma eğilimi yüksek; ancak kapatma tarihi net değilse gecikme riski var. Hafif yapı + check-in ile güven çok yükselir.\n- Persuasion susceptibility (supportive use only):\n  - Etkili: Ortak amaç, samimi takdir, kullanıcı-insan hikâyeleri, seçim özgürlüğü.\n  - Etkisiz: Baskı, statü gösterisi, sırf para/rekabet vurgusu.\n- Opportunity vs. risk:\n  - Fırsat: Ürün/deneyim empatisi, vizyon üretme, hikâyeleştirme, değer mimarisi.\n  - Risk: Kapsam şişmesi, karar gecikmesi, operasyonel detaylarda yorgunluk.\n- Risk–benefit view for others:\n  - En iyi haliniz: Sizi amacı olan işlere koyun, sessiz odak verin, ilerlemeyi küçük kapılarla takip edin.\n  - Kaçınılması gereken: Sürekli anlık değişiklik, muğlak beklenti, kişisel zamana saygısızlık.\n\n### 7) Conclusion & Recommendations\n- 5–7 somut hamle:\n  - “Şimdi/sonra” listesi: Günün ilk 3 görevi (şimdi), sonraki 3 (sonra).\n  - Zaman kutulama: 2×50 dk sessiz blok + 10 dk “kapatma” notu.\n  - 48 saatlik karar penceresi + “yeterince iyi” tanımı (3 kriter).\n  - İki cümlelik sınır: “İhtiyacım X; Y yapamam; Z alternatif.”\n  - Haftalık “anlam kontrolü”: İş/hedefler değerlerle uyumlu mu?\n  - Geri bildirimde “ben-dili + tek istek” formatını standartlaştır.\n  - Operasyonel işlerde mini şablon: kontrol listesi, hazır metin, snippet.\n- How to approach you:\n  - İyi işler: Kısa özet + amaç bağlantısı + esneklik payı.\n  - Kaçınılacaklar: Baskı tonu, muğlak talimat, toplantı kalabalığı.\n- 30 günlük mikro plan:\n  - Hafta 1: Günlük 20 dk derin-iş ritüeli; akşam 3 cümle gün özeti.\n  - Hafta 2: İki cümlelik sınır cümlelerinizi yazıp 1 gerçek durumda uygulayın.\n  - Hafta 3: Karar penceresi kuralını 3 kararda deneyin; sonuçları not edin.\n  - Hafta 4: En çok sürtünme yaratan rutini sadeleştirin (tek şablon seçin).\n  - Sürekli: Haftada 1 kez 15 dk “anlam kontrolü”; 1–2 kısa check-in mesajı.\n\n### 8) Quality & Uncertainty Notes\n- Yaşam bağlamı (S0) boş; bu nedenle örnekleme yapamadım. S1’in büyük kısmında yanıt görünmüyor; yalnızca MBTI zorunlu seçimlerde tutarlı bir I–N–F–P deseni var. Bu yüzden eksenler için orta düzeyde güven, diğer alanlar için düşük–orta güven söz konusu. Gözlem ve küçük deneylerle doğrulamayı öneririm.\n\n### 9) Item Signal Summary (S0 + S1)\n- Yalnız kalınca daha iyi şarj oluyorsun. [preference | “boşluk planla”]\n- Sakin ortamları kalabalığa yeğlersin. [preference | “sessiz bloklar”]\n- Fikir ve olasılıklar seni heyecanlandırır. [trait-support | “beyin fırtınası”]\n- Büyük resmi önce görmeyi istersin. [trait-support | “özetle başla”]\n- Gelecekteki potansiyeli merak edersin. [trait-support | “vizyon dakikası”]\n- Kararlarda insan etkisini önemsersin. [trait-support | “paydaşları düşün”]\n- Geri bildirimi yumuşatmaya eğilimlisin. [trait-support | “ben-dili”]\n- Uyum ve ilişkileri gözetirsin. [trait-support | “müttefik kazan”]\n- Esnek kalmayı ve seçenekleri açık tutmayı seversin. [trait-support | “opsiyon bırak”]\n- Belirsizliği tolere edebilirsin. [trait-support | “zaman kutuları”]\n- S0 yanıtları boş; bağlam eksik. [quality-check | “daha fazla veri”]\n- Diğer ölçekler işaretlenmemiş. [quality-check | “tamamla”]\n\nThese forward-looking and intuitive points are hypotheses drawn from patterns and may be wrong—treat them as starting points to observe, test, and adjust.\n\n### notes-for-lifecoaching:\n```json\n{\n  "language": "tr",\n  "mbti_primary": "INFP",\n  "mbti_alternates": ["ENFP", "INFJ"],\n  "confidence_band": "medium",\n  "summary_one_liner": "İçe dönük, değer odaklı, esnek; derin bağları ve anlamı arar, yapı baskısı ve yüzeysellikte zorlanır.",\n  "motivations": ["meaning", "autonomy", "care", "mastery"],\n  "communication": {\n    "tone": "warm",\n    "preferred_channels": ["Text", "InPerson"],\n    "feedback_style": "Feeling",\n    "contact_freq": "Weekly",\n    "privacy_expectation_level": 4\n  },\n  "decision_style": "intuitive",\n  "pressure_response": "withdraws",\n  "routines_that_help": ["time-boxing", "sessiz odak blokları", "kısa niyet yazısı"],\n  "triggers": ["aceleye zor	\N	\N	0	2025-08-20 02:58:09.738153+03	2025-08-20 03:00:01.596075+03	{"language": "tr", "language_ok": true}
b7b60dbd-a007-42af-a4a1-940dc827171a	ebe6eee2-01ae-4753-9737-0983b0330880	self	completed	{}	{}	Merhaba — yanıtlarınızdan gördüğüm kadarıyla içe dönük, anlam arayan ve esnek kalmayı seven bir profil çiziyorsunuz. Aşağıda, MBTI tarzı bir çalışma hipotezi ve günlük hayatta işe yarayacak bir okuma bulacaksınız. Bu bir tanı değil; size ayna tutan, pratikte test edip uyarlayabileceğiniz bir çerçevedir.\n\n1) MBTI hipotezi (gündelik dille)\nBirincil hipotez: INFP\n- Enerji: Kalabalıktan çok tek başına kalarak şarj olma eğilimi.\n- Bilgiye bakış: Büyük resme ve “ne olabilir?” sorusuna meyil; olasılıklar ve anlam katmanları ilginizi çekiyor.\n- Karar verme: Mantık dışlanmıyor ama değerler, etki ve insan boyutu daha baskın.\n- Yapı/akış: Kesin planlara kilitlenmek yerine seçenekleri bir süre açık tutmayı seviyorsunuz.\n\nYakın iki alternatif:\n- INFJ: Değer ve anlam yine merkezde olur; fakat plan, ritim ve kapatma ihtiyacı belirginleşirse bu profile yaklaşır.\n- ISFP: Değer odaklılık korunurken soyut fikirlerden ziyade somut deneyimler ve bedensel/duyusal taraf öne çıkarsa buraya kayabilir.\n\nNe teyit eder, neyi değiştirir?\n- INFP’yi teyit: Yalnız zamanlardan tazelenmiş çıkmanız; kararları “benim için doğru mu?” filtresinden geçirmeniz; esnek planlara sıcak olmanız.\n- INFJ’ye kaydırır: Net takvim, kontrol listesi ve hızlı kapatma ihtiyacı belirginleşirse.\n- ISFP’ye kaydırır: “Şimdi ve burada”ya, yaşantısal/somut ayrıntılara açık bir tercih baskınsa.\n- Daha dışa dönük hissedip kalabalıkla enerji topladığınızı sık sık fark ederseniz ENFP de akla gelebilir.\n\n2) Kişilik özellikleri\n- Mizaç: Sakin, iç gözleme açık, bağımsız düşünmeyi seven. “Neden?” ve “neye hizmet ediyor?” soruları sizin için önemli.\n- Güçlü yanlar: Empati, yaratıcı düşünme, değer tutarlılığı, esneklik, derin odaklandığınızda özgün üretim.\n- Dikkat edilmesi gerekenler: Aşırı seçenek açık tutma yüzünden erteleme; “mükemmel”e yaklaşma arzusu nedeniyle başlamada/bitirmede zorlanma; duygusal yükleri fazla omuzlama.\n- İletişim tarzı: Nazik ve ilişki gözeten bir dil. Sert, kaba üslup motivasyonu düşürebilir; fakat net çerçeve ve gerekçelendirilmiş istekler sizde olumlu çalışır.\n- Risk iştahı: Genelde ölçülü. Değerle örtüşen sosyal/yaratıcı riskleri alabilirsiniz; mali/itibar risklerinde temkin artar.\n\n3) Davranış kalıpları\n- Krizde ilk refleks: Sakin kalıp anlamlandırmaya çalışma eğilimi. Önce duyguyu regüle edip küçük ve uygulanabilir bir adım belirlemek size iyi gelir.\n- Karar yapısı: “Değer filtresi + sezgi + kısa bir opsiyon taraması”. Kapanışı çok ertelememek için kendinize bir “son tarih” koymak verimi artırır.\n- Rutinler ve sürtünmeler: Sessiz odak blokları ve esnek zaman planı iyi gelir. Tekdüze ve anlamı belirsiz işler motivasyonu düşürür; amaç hatırlatma burada işe yarar.\n- Baskı altında zincir: Baskı artar → içe çekilme → “bunun anlamı ne?” arayışı → küçük adımlara bölme. Bu zincirin “erteleme” halkasını kırmak için iki dakikalık mikro başlangıçlar etkilidir.\n- Güvenlik farkındalığı: Kişisel alan ve saygı temel. “Kibarca evet” deyip içten istemediğiniz işleri üstlenmek yorucu olabilir; erken sınır belirlemek koruyucudur.\n\n4) Psikolojik profil\n- Duygusal denge: Duygular derin ve anlam yüklü. Zihinsel yeniden çerçeveleme (olaya başka bir açıdan bakma) size iyi gelebilir; fakat duyguyu bastırmak yerine düzenlemeyi tercih etmek daha sürdürülebilirdir.\n- Ego duruşu: Alçakgönüllü ve özgün. Dış onaydan çok iç tutarlılık peşindesiniz; yine de yakın çevreden şefkatli geri bildirim motive eder.\n- Çekirdek motivasyonlar: Anlam, özgünlük, başkalarına katkı, yaratıcılık. “Ben kimim ve neyin temsilcisiyim?” soruları yön veriyor.\n- Olası hassasiyetler ve onarımlar: \n  - Aşırı sorumluluk alma → Paylaşılabilir işleri paylaşın, net “hayır” cümleleri hazırlayın.\n  - İdealleştirme ve hayal kırıklığı → “İyi-kâfi” standardını tanımlayın; her işte “mükemmel” değil “ilerleme” hedefleyin.\n  - Belirsizlikte savrulma → Üç seçenek kuralı ve mini kapanış ritüelleri kullanın.\n\n5) Sosyal ilişkiler\n- Otoriteye tutum: Seçici ve ilke odaklı. Saygı ve anlam gördüğünüz yerde sadıksınız; keyfi, kaba otoriteye mesafelisiniz.\n- Başkalarına etkisi: Güven veren dinleyici, rahatlatıcı varlık. İnsanlar sizinle derin sohbetlere açılabilir.\n- Kolay bağ kurulan alanlar: Bire bir sohbetler, ortak değer/amaç etrafında buluşmalar, yaratıcı işbirlikleri.\n- Sürtünme ihtimali olan alanlar: Çok rekabetçi, hızlı ve emredici üslup; sonuç uğruna ilişkiyi görmezden gelen yaklaşımlar.\n\n6) Stratejik bakış (etik, işbirlikçi)\n- Güvenilirlik: Niyet ve değer tutarlılığınız yüksek. Takvim disiplini, esneklik tercihi nedeniyle dalgalanabilir; görünür mikro planlar bunu dengeler.\n- Destekleyici ikna açıklığı: Değerlerinizle hizalanan, seçim hakkı tanıyan ve faydasını somut örnekle anlatan teklifler sizde çalışır. Baskı ve manipülasyon ters teper.\n- Fırsat vs. risk: \n  - Fırsat: Yaratıcı üretim, anlam odaklı projeler, mentorluk/rehberlik, yazma-anlatma alanları.\n  - Risk: Sonsuz seçenek araştırması, net sınır koyamama, aşırı yüklenme.\n- Uzun vadeli yönelim: Anlamlı etki bırakmak ve bir konuda ustalık kazanmak. Derinleşmek için ritim ve kapanış ritüelleri önemli.\n- Kısa risk–fayda notu (sizinle çalışacaklar için): Nazik ama muğlak talepler yerine, amaç bağını kuran net çerçeve sunun; iki-üç seçenek verin; karar için insaflı bir süre tanıyın; sonrasında kapatmayı birlikte yapın.\n\n7) Sonuç ve öneriler\nSomut hamleler:\n1) Değer haritanızı yazın: En çok önem verdiğiniz 3 değeri ve bunun günlük karşılığını belirleyin.\n2) Üç seçenek kuralı: Bir kararda en fazla üç alternatif, artı bir “en olası adım” notu.\n3) Mini kapanış ritüeli: “Bitti” demek için dosyaya kısa bir sonuç cümlesi ekleyin; küçük kutlama yapın.\n4) Zaman blokları: Günde bir kez 60–90 dakikalık sessiz odak. Öncesinde 5 dakika niyet, sonunda 5 dakika not.\n5) Sınır cümleleri: “Şu anda kapasitem dolu, X tarihinden sonra bakabilirim.” gibi iki hazır cümleyi ezberleyin.\n6) Geri bildirim reçetesi: Önce niyet ve değer, sonra somut öneri, ardından küçük bir sonraki adım.\n7) Duygu düzenleme: Zor duyguda 90 saniyelik nefes + kısa yazı; ardından küçük eylem.\n\n30 günlük mikro-plan:\n- Günlük: 10 dakika “niyet ve kapanış” notu (sabah niyet, akşam kapanış).\n- Haftada 2 kez: Sessiz odak bloğu ve tek bir işin bitişi.\n- Haftada 1 kez: Değerlerle uyum kontrolü; “Bu hafta yaptıklarımdan hangisi değerlerimi yaşattı?” sorusu.\n- Haftada 1 kez: Bir “hayır” pratik edin; kibar ve net.\n- Ay sonunda: Bir sayfalık geri bakış; neler ilerledi, neyi sadeleştirirsiniz?\n\n8) Kalite ve belirsizlik\nYaşam bağlamına (iş, ilişki, stres, rutin) dair veri paylaşmadınız; ayrıca bazı ölçeklerde belirgin yanıt yok. Bu yüzden kesinlik düşük; bu metni deneme-yanılma rehberi olarak görün. Özellikle enerji yönetimi (kalabalık vs. yalnız zaman), karar kapatma ritmi ve değer uyumu konusunda bir ay gözlem yapmanız, profili netleştirir. Gözlemlerinize göre hipotezi güncelleyebiliriz.\n\nBu ileriye dönük ve sezgisel çıkarımlar, kalıplardan türetilmiş hipotezlerdir ve hatalı olabilir; lütfen gözlemleyin, deneyin ve gerektiğinde uyarlayın.\n\n```json\n{\n  "language": "tr",\n  "mbti_primary": "INFP",\n  "mbti_alternates": ["INFJ", "ISFP"],\n  "confidence_band": "low",\n  "summary_one_liner": "İçe dönük, değer odaklı, yaratıcı ve esnek; anlam arayışı güçlü.",\n  "motivations": ["meaning", "autonomy", "care", "mastery"],\n  "communication": {\n    "tone": "warm",\n    "feedback_style": "Feeling"\n  },\n  "decision_style": "intuitive",\n  "pressure_response": "withdraws",\n  "routines_that_help": ["sessiz odak blokları", "mini kapanış ritüeli"],\n  "triggers": ["sert üslup", "acele karar baskısı"],\n  "soothing_strategies": ["yazma", "nefes", "kısa yürüyüş"],\n  "boundaries": ["kişisel alan", "değerlere aykırı talepler"],\n  "risk_appetite": "moderate",\n  "social_action_style": "supportive",\n  "authority_stance": "selective",\n  "near_term_focus": ["self_growth", "relationships"],\n  "do_not": ["baskıyla hızlı karar zorlamak"]\n}\n```	\N	\N	0	2025-08-20 03:33:21.015631+03	2025-08-20 03:35:55.261929+03	{"language": "tr", "language_ok": true}
\.


--
-- Data for Name: assessments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assessments (id, person_id, type, version, created_at) FROM stdin;
\.


--
-- Data for Name: chat_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_sessions (id, dyad_id, metadata) FROM stdin;
\.


--
-- Data for Name: dyad_scores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dyad_scores (id, dyad_id, compatibility_score, strengths_json, risks_json, plan_json, confidence) FROM stdin;
\.


--
-- Data for Name: dyads; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dyads (id, a_person_id, b_person_id, relation_type) FROM stdin;
\.


--
-- Data for Name: iap_products; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- Data for Name: iap_purchases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.iap_purchases (id, user_id, platform, product_id, transaction_id, receipt_data, validation_status, validation_response, created_at, validated_at) FROM stdin;
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items (id, form, section, subscale, text_tr, type, options_tr, reverse_scored, scoring_key, weight, notes, display_order) FROM stdin;
S1_BF_E1	S1_self	BigFive	E	Sosyal ortamlarda enerji toplarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_E2	S1_self	BigFive	E	Yeni insanlarla tanışmak beni heyecanlandırır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_E3	S1_self	BigFive	E	Kalabalık etkinlikler beni yorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S1_BF_E4	S1_self	BigFive	E	Topluluk önünde konuşmaktan keyif alırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_A1	S1_self	BigFive	A	İnsanların bakış açısını anlamaya çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_A2	S1_self	BigFive	A	Anlaşmazlıklarda empati kurarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_A3	S1_self	BigFive	A	Eleştirirken sözlerimi özenle seçerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_A4	S1_self	BigFive	A	Kendi ihtiyaçlarımı her zaman öne koyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S1_BF_C1	S1_self	BigFive	C	Planları önceden yapar ve takip ederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_C2	S1_self	BigFive	C	Detayları gözden kaçırmam.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_C3	S1_self	BigFive	C	Son dakika işleri severim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S1_BF_C4	S1_self	BigFive	C	Söz verdiğim işi vaktinde bitiririm.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_N1	S1_self	BigFive	N	Stresliyken kolayca gerginleşirim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_N2	S1_self	BigFive	N	Eleştirilere karşı hassasım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_N3	S1_self	BigFive	N	Zor durumda soğukkanlı kalırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S1_BF_N4	S1_self	BigFive	N	Gelecek hakkında sık endişe duyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_O1	S1_self	BigFive	O	Yeni fikir ve deneyimlere açığım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_O2	S1_self	BigFive	O	Rutini kırmayı severim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_O3	S1_self	BigFive	O	Alışılmış yöntemler dışına çıkmam.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S1_BF_O4	S1_self	BigFive	O	Sanat/yaratıcılık içeren şeylerden keyif alırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_MB_FC1	S1_self	MBTI	EI	A) Kalabalıkta enerji toplarım  |  B) Yalnız kalarak şarj olurum	ForcedChoice2	A|B	0	{"A":"EI:E","B":"EI:I"}	1	Ipsatif (sosyal beğenirlik azaltma)	\N
S1_MB_FC2	S1_self	MBTI	EI	A) Yeni insanlarla hızla bağ kurarım  |  B) Önce gözlemler sonra açılırım	ForcedChoice2	A|B	0	{"A":"EI:E","B":"EI:I"}	1	\N	\N
S1_MB_FC3	S1_self	MBTI	EI	A) Yüksek sesli ve hareketli ortamlar beni canlandırır  |  B) Sessiz ve sakin ortamları tercih ederim	ForcedChoice2	A|B	0	{"A":"EI:E","B":"EI:I"}	1	\N	\N
S1_MB_FC4	S1_self	MBTI	SN	A) Gerçekler ve kanıtlar  |  B) Fikirler ve olasılıklar beni daha çok cezbeder	ForcedChoice2	A|B	0	{"A":"SN:S","B":"SN:N"}	1	\N	\N
S1_MB_FC5	S1_self	MBTI	SN	A) Detaylara odaklanırım  |  B) Büyük resmi görmeyi tercih ederim	ForcedChoice2	A|B	0	{"A":"SN:S","B":"SN:N"}	1	\N	\N
S1_MB_FC6	S1_self	MBTI	SN	A) Mevcut duruma dayanırım  |  B) Gelecekteki potansiyeli merak ederim	ForcedChoice2	A|B	0	{"A":"SN:S","B":"SN:N"}	1	\N	\N
S1_MB_FC7	S1_self	MBTI	TF	A) Kararda tutarlılık ve mantık  |  B) Etki ve duygular önceliklidir	ForcedChoice2	A|B	0	{"A":"TF:T","B":"TF:F"}	1	\N	\N
S1_MB_FC8	S1_self	MBTI	TF	A) Doğrudan geri bildirim veririm  |  B) İncitmemek için dili yumuşatırım	ForcedChoice2	A|B	0	{"A":"TF:T","B":"TF:F"}	1	\N	\N
S1_MB_FC9	S1_self	MBTI	TF	A) Adalet ve ilke  |  B) İlişki ve uyum önce gelir	ForcedChoice2	A|B	0	{"A":"TF:T","B":"TF:F"}	1	\N	\N
S1_MB_FC10	S1_self	MBTI	JP	A) Plan ve takvim isterim  |  B) Esnek kalmayı severim	ForcedChoice2	A|B	0	{"A":"JP:J","B":"JP:P"}	1	\N	\N
S1_MB_FC11	S1_self	MBTI	JP	A) Kararı hızlıca kapatırım  |  B) Seçenekleri bir süre açık tutarım	ForcedChoice2	A|B	0	{"A":"JP:J","B":"JP:P"}	1	\N	\N
S1_MB_FC12	S1_self	MBTI	JP	A) Belirsizlik rahatsız eder  |  B) Akışına bırakabilirim	ForcedChoice2	A|B	0	{"A":"JP:J","B":"JP:P"}	1	\N	\N
S1_AT_ANX1	S1_self	Attachment	ANX	Partnerim geç yanıt verdiğinde huzursuz olurum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	ECR-R esinli	\N
S1_AT_ANX2	S1_self	Attachment	ANX	İlişkide sık sık güvence ihtiyacı hissederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_ANX3	S1_self	Attachment	ANX	Terk edilme korkusu zaman zaman aklıma gelir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_ANX4	S1_self	Attachment	ANX	Partnerimin sevgisini kanıtlamasına sık ihtiyaç duyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_ANX5	S1_self	Attachment	ANX	İlişkiyle ilgili olumsuz senaryoları zihnimde canlandırırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_ANX6	S1_self	Attachment	ANX	Partnerimle aram bozulduğunda hızla paniğe kapılırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO1	S1_self	Attachment	AVO	Duygularımı paylaşmakta zorlanırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO2	S1_self	Attachment	AVO	Yakınlık arttığında bir miktar geri çekilme ihtiyacı duyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO3	S1_self	Attachment	AVO	Bağımsızlık alanım kısıtlanınca huzursuz olurum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO4	S1_self	Attachment	AVO	Partnerimin duygusal ihtiyaçlarını karşılamak yorucu gelebilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO5	S1_self	Attachment	AVO	Problem olduğunda konuyu ertelemeyi tercih ederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO6	S1_self	Attachment	AVO	Kişisel alanımın korunması benim için çok önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_ERQ_REAPP1	S1_self	EmotionReg	REAPP	Olumsuz bir olayı kafamda yeniden çerçevelemeye çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	ERQ (yeniden değerlendirme) esinli	\N
S1_TKI_1	S1_self	Conflict	COMPETE	Evde ortak alanın dağınıklığı konusunda anlaşmazlık var; ilk eğiliminiz?	MultiChoice5	Bugünden itibaren net kurallar koyarım; uymayana açıkça uyarı yaparım.|Beraber kısa bir toplantı yapıp kural + görev paylaşımı oluşturmayı öneririm.|"Bu hafta ben, gelecek hafta siz" gibi orta yol teklif ederim.|Şimdilik açmam; uygun bir zamanda sakinleşince konuşmak isterim.|Sorun etmeyip ben toparlarım; siz nasıl rahatsanız öyle olsun.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	Günlük yaşam SJT	\N
S1_TKI_4	S1_self	Conflict	AVOID	Kalabalıkta biri sıranızı kesti; tepkiniz?	MultiChoice5	Netçe uyarır, yerime dönmesini isterim.|Çevreyle birlikte sırayı düzenleyelim, kibarca kuralı hatırlatırım.|Aceleyse bu kez geçmesine izin verelim; sırayı birlikte netleştirelim.|Tartışmaya girmem; görmezden gelirim.|Rahatsız olsam da sıramı veririm, mesele büyümesin.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	\N	\N
S1_TKI_5	S1_self	Conflict	ACCOM	Yakınınız bir konuda duygusal olarak çok yoğun; yaklaşımınız?	MultiChoice5	Konuyu çözüme bağlamak için yönlendirir, somut adımlar belirlerim.|Hisleri ve ihtiyaçları birlikte konuşur, ortak plan çıkarırız.|Biraz konuşup orta noktada buluşalım, sonra kapatalım derim.|Şu an uygun değil; sakinleşince konuşalım derim.|Ne istiyorsa öyle yaparım; ona uyarım.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	\N	\N
S1_TKI_7	S1_self	Conflict	COMPETE	Bir konuda doğru olduğunuzdan eminsiniz ve kanıt elinizde; stratejiniz?	MultiChoice5	Kanıtları sunar, kararı netleştiririm.|Kanıtları paylaşıp birlikte değerlendirir, ortak karar alırız.|Zaman kaybetmemek için kısmi uzlaşma öneririm.|Tartışmayı uzatmam; konuyu büyütmeden geçerim.|Karşı tarafı kırmamak için kendi görüşümden vazgeçerim.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	\N	\N
S1_ERQ_REAPP2	S1_self	EmotionReg	REAPP	Zor bir durumda durumu farklı bakış açılarından görmeye çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_ERQ_SUPPR1	S1_self	EmotionReg	SUPPR	Duygularımı dışa yansıtmamayı tercih ederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	ERQ (bastırma) esinli	\N
S1_ERQ_SUPPR2	S1_self	EmotionReg	SUPPR	Üzgün olsam bile yüzüme yansıtmam.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_ERQ_SUPPR3	S1_self	EmotionReg	SUPPR	Toplum içinde duygusal tepkilerimi bastırırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_EMP_PT1	S1_self	Empathy	PT	Birinin bakış açısını anlamak için aktif çaba gösteririm.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	IRI esinli	\N
S1_EMP_PT2	S1_self	Empathy	PT	Tartışmada karşı tarafın gerekçelerini anlamaya çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_EMP_EC1	S1_self	Empathy	EC	Başkalarının acısı beni duygusal olarak etkiler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_EMP_EC2	S1_self	Empathy	EC	Zor durumda olanlara karşı şefkat hissederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_OE_STRENGTHS	S1_self	OpenEnded	OE	Kendinizde en güçlü bulduğunuz 3 özelliği yazınız.	OpenText		0	\N	1	\N	\N
S1_OE_WEAK	S1_self	OpenEnded	OE	Geliştirmek istediğiniz 3 alanı yazınız.	OpenText		0	\N	1	\N	\N
S1_OE_HAPPY	S1_self	LifeStory	OpenEnded	En mutlu anılarınızdan 1–3 tanesini yazınız (her biri ayrı paragraf).	OpenText		0	\N	1	Opsiyonel	\N
S1_OE_HARD	S1_self	LifeStory	OpenEnded	En zor/kötü anılarınızdan 1–3 tanesini yazınız (her biri ayrı paragraf).	OpenText		0	\N	1	Opsiyonel; travmatik detay şart değil	\N
S1_Q_CONS	S1_self	Quality	CONS	Bu testte dürüst cevap verdiğime inanıyorum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_Q_SPEED	S1_self	Quality	SPEED	Soruları acele etmeden yanıtladım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	RT kalite ile birlikte kullanın	\N
S1_Q_REPEAT	S1_self	Quality	REPEAT	Benzer sorulara farklı cevap verdiğimi düşünüyorum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	Tutarlılık	\N
S1_Q_ATTN	S1_self	Quality	IMC	Dikkat kontrolü: Lütfen bu madde için 'Katılıyorum' yani 4 nolu seçeneğini işaretleyiniz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	{"target":"Katılıyorum"}	1	Instructional Manipulation Check	\N
S2R_mother_E1	S2R_mother	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_A1	S2R_mother	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_C1	S2R_mother	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_N1	S2R_mother	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_O1	S2R_mother	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_E2	S2R_mother	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mother_EI1	S2R_mother	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_EI2	S2R_mother	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mother_SN1	S2R_mother	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_SN2	S2R_mother	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mother_TF1	S2R_mother	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mother_TF2	S2R_mother	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_JP1	S2R_mother	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_JP2	S2R_mother	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mother_COM1	S2R_mother	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_COL1	S2R_mother	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_CRM1	S2R_mother	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_AVD1	S2R_mother	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_ACM1	S2R_mother	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_COL2	S2R_mother	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_CLOSE1	S2R_mother	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_CLOSE2	S2R_mother	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_CLOSE3	S2R_mother	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_CLOSE4	S2R_mother	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VAL1	S2R_mother	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VAL2	S2R_mother	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VAL3	S2R_mother	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VAL4	S2R_mother	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VIG1	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mother_VIG2	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mother_VIG3	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_sibling_VAL3	S2R_sibling	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VIG4	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mother_CONF1	S2R_mother	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_FREQ1	S2R_mother	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_father_E1	S2R_father	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_A1	S2R_father	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_C1	S2R_father	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_N1	S2R_father	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_O1	S2R_father	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_E2	S2R_father	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_father_EI1	S2R_father	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_EI2	S2R_father	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_father_SN1	S2R_father	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_SN2	S2R_father	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_father_TF1	S2R_father	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_father_TF2	S2R_father	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_JP1	S2R_father	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_JP2	S2R_father	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_father_COM1	S2R_father	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_COL1	S2R_father	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_CRM1	S2R_father	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_AVD1	S2R_father	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_ACM1	S2R_father	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_COL2	S2R_father	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_CLOSE1	S2R_father	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_CLOSE2	S2R_father	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_CLOSE3	S2R_father	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_CLOSE4	S2R_father	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_VAL1	S2R_father	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_VAL2	S2R_father	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_VAL3	S2R_father	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_VAL4	S2R_father	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_VIG1	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_father_VIG2	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_father_VIG3	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_father_VIG4	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_father_CONF1	S2R_father	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_FREQ1	S2R_father	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_sibling_E1	S2R_sibling	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_A1	S2R_sibling	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_C1	S2R_sibling	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_N1	S2R_sibling	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_O1	S2R_sibling	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_E2	S2R_sibling	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_sibling_EI1	S2R_sibling	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_EI2	S2R_sibling	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_sibling_SN1	S2R_sibling	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_SN2	S2R_sibling	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_sibling_TF1	S2R_sibling	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_sibling_TF2	S2R_sibling	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_JP1	S2R_sibling	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_JP2	S2R_sibling	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_sibling_COM1	S2R_sibling	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_COL1	S2R_sibling	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_CRM1	S2R_sibling	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_AVD1	S2R_sibling	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_ACM1	S2R_sibling	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_COL2	S2R_sibling	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_CLOSE1	S2R_sibling	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_CLOSE2	S2R_sibling	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_CLOSE3	S2R_sibling	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_CLOSE4	S2R_sibling	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_VAL1	S2R_sibling	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_VAL2	S2R_sibling	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_VAL4	S2R_sibling	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_VIG1	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_sibling_VIG2	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_sibling_VIG3	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_sibling_VIG4	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_sibling_CONF1	S2R_sibling	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_FREQ1	S2R_sibling	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_relative_E1	S2R_relative	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_A1	S2R_relative	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_C1	S2R_relative	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_N1	S2R_relative	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_O1	S2R_relative	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_E2	S2R_relative	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_relative_EI1	S2R_relative	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_EI2	S2R_relative	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_relative_SN1	S2R_relative	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_SN2	S2R_relative	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_relative_TF1	S2R_relative	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_relative_TF2	S2R_relative	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_JP1	S2R_relative	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_JP2	S2R_relative	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_relative_COM1	S2R_relative	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_COL1	S2R_relative	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_CRM1	S2R_relative	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_AVD1	S2R_relative	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_ACM1	S2R_relative	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_COL2	S2R_relative	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_CLOSE1	S2R_relative	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_CLOSE2	S2R_relative	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_CLOSE3	S2R_relative	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_CLOSE4	S2R_relative	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_VAL1	S2R_relative	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_VAL2	S2R_relative	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_VAL3	S2R_relative	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_VAL4	S2R_relative	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_VIG1	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_relative_VIG2	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_relative_VIG3	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_relative_VIG4	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_relative_CONF1	S2R_relative	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_FREQ1	S2R_relative	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_best_friend_E1	S2R_best_friend	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_A1	S2R_best_friend	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_C1	S2R_best_friend	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_N1	S2R_best_friend	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_O1	S2R_best_friend	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_E2	S2R_best_friend	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_best_friend_EI1	S2R_best_friend	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_EI2	S2R_best_friend	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_best_friend_SN1	S2R_best_friend	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_SN2	S2R_best_friend	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_best_friend_TF1	S2R_best_friend	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_best_friend_TF2	S2R_best_friend	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_JP1	S2R_best_friend	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_JP2	S2R_best_friend	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_best_friend_COM1	S2R_best_friend	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_COL1	S2R_best_friend	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_CRM1	S2R_best_friend	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_AVD1	S2R_best_friend	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_ACM1	S2R_best_friend	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_COL2	S2R_best_friend	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_AVAIL1	S2R_best_friend	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_AVAIL2	S2R_best_friend	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_AVAIL3	S2R_best_friend	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_AVAIL4	S2R_best_friend	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_VAL1	S2R_best_friend	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_VAL2	S2R_best_friend	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_VAL3	S2R_best_friend	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_VAL4	S2R_best_friend	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_VIG1	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_best_friend_VIG2	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_best_friend_VIG3	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_best_friend_VIG4	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_best_friend_CONF1	S2R_best_friend	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_FREQ1	S2R_best_friend	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_friend_E1	S2R_friend	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_A1	S2R_friend	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_C1	S2R_friend	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_N1	S2R_friend	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_O1	S2R_friend	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_E2	S2R_friend	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_friend_EI1	S2R_friend	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_EI2	S2R_friend	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_friend_SN1	S2R_friend	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_SN2	S2R_friend	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_friend_TF1	S2R_friend	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_friend_TF2	S2R_friend	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_JP1	S2R_friend	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_JP2	S2R_friend	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_friend_COM1	S2R_friend	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_COL1	S2R_friend	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_CRM1	S2R_friend	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_AVD1	S2R_friend	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_ACM1	S2R_friend	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_COL2	S2R_friend	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_AVAIL1	S2R_friend	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_AVAIL2	S2R_friend	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_AVAIL3	S2R_friend	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_AVAIL4	S2R_friend	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_VAL1	S2R_friend	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_VAL2	S2R_friend	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_VAL3	S2R_friend	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_VAL4	S2R_friend	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_VIG1	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_friend_VIG2	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_friend_VIG3	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_friend_VIG4	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_friend_CONF1	S2R_friend	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_FREQ1	S2R_friend	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_roommate_E1	S2R_roommate	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_A1	S2R_roommate	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_C1	S2R_roommate	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_N1	S2R_roommate	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_O1	S2R_roommate	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_E2	S2R_roommate	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_roommate_EI1	S2R_roommate	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_EI2	S2R_roommate	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_roommate_SN1	S2R_roommate	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_SN2	S2R_roommate	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_roommate_TF1	S2R_roommate	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_roommate_TF2	S2R_roommate	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_JP1	S2R_roommate	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_JP2	S2R_roommate	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_roommate_COM1	S2R_roommate	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_COL1	S2R_roommate	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_CRM1	S2R_roommate	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_AVD1	S2R_roommate	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_ACM1	S2R_roommate	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_COL2	S2R_roommate	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_AVAIL1	S2R_roommate	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_AVAIL2	S2R_roommate	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_AVAIL3	S2R_roommate	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_AVAIL4	S2R_roommate	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_VAL1	S2R_roommate	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_VAL2	S2R_roommate	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_VAL3	S2R_roommate	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_VAL4	S2R_roommate	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_VIG1	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_roommate_VIG2	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_roommate_VIG3	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_roommate_VIG4	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_roommate_CONF1	S2R_roommate	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_FREQ1	S2R_roommate	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_neighbor_E1	S2R_neighbor	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_A1	S2R_neighbor	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_C1	S2R_neighbor	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_N1	S2R_neighbor	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_O1	S2R_neighbor	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_E2	S2R_neighbor	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_neighbor_EI1	S2R_neighbor	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_EI2	S2R_neighbor	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_neighbor_SN1	S2R_neighbor	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_SN2	S2R_neighbor	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_neighbor_TF1	S2R_neighbor	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_neighbor_TF2	S2R_neighbor	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_JP1	S2R_neighbor	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_JP2	S2R_neighbor	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_neighbor_COM1	S2R_neighbor	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_COL1	S2R_neighbor	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_CRM1	S2R_neighbor	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_AVD1	S2R_neighbor	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_ACM1	S2R_neighbor	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_COL2	S2R_neighbor	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_AVAIL1	S2R_neighbor	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_AVAIL2	S2R_neighbor	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_AVAIL3	S2R_neighbor	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_AVAIL4	S2R_neighbor	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_VAL1	S2R_neighbor	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_VAL2	S2R_neighbor	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_VAL3	S2R_neighbor	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_VAL4	S2R_neighbor	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_VIG1	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_neighbor_VIG2	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_neighbor_VIG3	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_neighbor_VIG4	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_neighbor_CONF1	S2R_neighbor	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_FREQ1	S2R_neighbor	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_crush_E1	S2R_crush	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_A1	S2R_crush	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_C1	S2R_crush	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_N1	S2R_crush	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_O1	S2R_crush	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_E2	S2R_crush	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_crush_EI1	S2R_crush	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_EI2	S2R_crush	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_crush_SN1	S2R_crush	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_SN2	S2R_crush	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_crush_TF1	S2R_crush	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_crush_TF2	S2R_crush	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_JP1	S2R_crush	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_JP2	S2R_crush	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_crush_COM1	S2R_crush	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_COL1	S2R_crush	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_CRM1	S2R_crush	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_AVD1	S2R_crush	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_ACM1	S2R_crush	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_COL2	S2R_crush	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_ANX1	S2R_crush	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_ANX2	S2R_crush	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_AVO1	S2R_crush	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_AVO2	S2R_crush	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_VAL1	S2R_crush	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_VAL2	S2R_crush	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_VAL3	S2R_crush	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_VAL4	S2R_crush	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_VIG1	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_crush_VIG2	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_crush_VIG3	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_crush_VIG4	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_crush_CONF1	S2R_crush	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_FREQ1	S2R_crush	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_date_E1	S2R_date	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_A1	S2R_date	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_C1	S2R_date	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_N1	S2R_date	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_O1	S2R_date	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_E2	S2R_date	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_date_EI1	S2R_date	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_EI2	S2R_date	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_date_SN1	S2R_date	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_SN2	S2R_date	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_date_TF1	S2R_date	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_date_TF2	S2R_date	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_JP1	S2R_date	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_JP2	S2R_date	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_date_COM1	S2R_date	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_COL1	S2R_date	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_CRM1	S2R_date	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_AVD1	S2R_date	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_ACM1	S2R_date	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_COL2	S2R_date	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_ANX1	S2R_date	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_ANX2	S2R_date	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_AVO1	S2R_date	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_AVO2	S2R_date	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_VAL1	S2R_date	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_VAL2	S2R_date	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_VAL3	S2R_date	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_VAL4	S2R_date	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_PRO1	S2R_mentee	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_VIG1	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_date_VIG2	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_date_VIG3	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_date_VIG4	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_date_CONF1	S2R_date	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_FREQ1	S2R_date	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_partner_E1	S2R_partner	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_A1	S2R_partner	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_C1	S2R_partner	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_N1	S2R_partner	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_O1	S2R_partner	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_E2	S2R_partner	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_partner_EI1	S2R_partner	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_EI2	S2R_partner	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_partner_SN1	S2R_partner	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_SN2	S2R_partner	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_partner_TF1	S2R_partner	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_partner_TF2	S2R_partner	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_JP1	S2R_partner	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_JP2	S2R_partner	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_partner_COM1	S2R_partner	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_COL1	S2R_partner	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_CRM1	S2R_partner	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_AVD1	S2R_partner	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_ACM1	S2R_partner	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_COL2	S2R_partner	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_ANX1	S2R_partner	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_ANX2	S2R_partner	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_AVO1	S2R_partner	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_AVO2	S2R_partner	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_VAL1	S2R_partner	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_VAL2	S2R_partner	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_VAL3	S2R_partner	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_VAL4	S2R_partner	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_VIG1	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_partner_VIG2	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_partner_VIG3	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_partner_VIG4	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_partner_CONF1	S2R_partner	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_FREQ1	S2R_partner	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_fiance_E1	S2R_fiance	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_A1	S2R_fiance	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_C1	S2R_fiance	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_N1	S2R_fiance	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_O1	S2R_fiance	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_E2	S2R_fiance	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_fiance_EI1	S2R_fiance	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_EI2	S2R_fiance	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_fiance_SN1	S2R_fiance	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_SN2	S2R_fiance	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_fiance_TF1	S2R_fiance	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_fiance_TF2	S2R_fiance	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_JP1	S2R_fiance	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_JP2	S2R_fiance	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_fiance_COM1	S2R_fiance	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_COL1	S2R_fiance	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_CRM1	S2R_fiance	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_AVD1	S2R_fiance	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_ACM1	S2R_fiance	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_COL2	S2R_fiance	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_ANX1	S2R_fiance	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_ANX2	S2R_fiance	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_AVO1	S2R_fiance	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_AVO2	S2R_fiance	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_VAL1	S2R_fiance	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_VAL2	S2R_fiance	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_VAL3	S2R_fiance	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_VAL4	S2R_fiance	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_VIG1	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_fiance_VIG2	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_fiance_VIG3	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_fiance_VIG4	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_fiance_CONF1	S2R_fiance	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_FREQ1	S2R_fiance	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_spouse_E1	S2R_spouse	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_A1	S2R_spouse	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_C1	S2R_spouse	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_N1	S2R_spouse	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_O1	S2R_spouse	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_E2	S2R_spouse	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_spouse_EI1	S2R_spouse	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_EI2	S2R_spouse	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_spouse_SN1	S2R_spouse	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_SN2	S2R_spouse	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_spouse_TF1	S2R_spouse	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_spouse_TF2	S2R_spouse	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_JP1	S2R_spouse	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_JP2	S2R_spouse	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_spouse_COM1	S2R_spouse	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_COL1	S2R_spouse	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_CRM1	S2R_spouse	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_AVD1	S2R_spouse	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_ACM1	S2R_spouse	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_COL2	S2R_spouse	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_ANX1	S2R_spouse	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_ANX2	S2R_spouse	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_AVO1	S2R_spouse	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_AVO2	S2R_spouse	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_VAL1	S2R_spouse	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_VAL2	S2R_spouse	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_VAL3	S2R_spouse	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_VAL4	S2R_spouse	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_VIG1	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_spouse_VIG2	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_spouse_VIG3	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_spouse_VIG4	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_spouse_CONF1	S2R_spouse	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_FREQ1	S2R_spouse	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_coworker_E1	S2R_coworker	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_A1	S2R_coworker	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_C1	S2R_coworker	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_N1	S2R_coworker	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_O1	S2R_coworker	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_E2	S2R_coworker	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_coworker_EI1	S2R_coworker	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_EI2	S2R_coworker	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_coworker_SN1	S2R_coworker	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_SN2	S2R_coworker	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_coworker_TF1	S2R_coworker	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_coworker_TF2	S2R_coworker	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_JP1	S2R_coworker	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_JP2	S2R_coworker	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_coworker_COM1	S2R_coworker	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_COL1	S2R_coworker	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_CRM1	S2R_coworker	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_AVD1	S2R_coworker	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_ACM1	S2R_coworker	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_COL2	S2R_coworker	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_PRO1	S2R_coworker	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_PRO2	S2R_coworker	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_PRO3	S2R_coworker	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_PRO4	S2R_coworker	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_VAL1	S2R_coworker	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_VAL2	S2R_coworker	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_VAL3	S2R_coworker	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_VAL4	S2R_coworker	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_VIG1	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_coworker_VIG2	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_coworker_VIG3	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_coworker_VIG4	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_coworker_CONF1	S2R_coworker	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_FREQ1	S2R_coworker	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_manager_E1	S2R_manager	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_A1	S2R_manager	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_C1	S2R_manager	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_N1	S2R_manager	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_O1	S2R_manager	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_E2	S2R_manager	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_manager_EI1	S2R_manager	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_EI2	S2R_manager	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_manager_SN1	S2R_manager	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_SN2	S2R_manager	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_manager_TF1	S2R_manager	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_manager_TF2	S2R_manager	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_JP1	S2R_manager	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_JP2	S2R_manager	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_manager_COM1	S2R_manager	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_COL1	S2R_manager	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_CRM1	S2R_manager	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_AVD1	S2R_manager	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_ACM1	S2R_manager	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_COL2	S2R_manager	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_PRO1	S2R_manager	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_PRO2	S2R_manager	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_PRO3	S2R_manager	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_PRO4	S2R_manager	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_VAL1	S2R_manager	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_VAL2	S2R_manager	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_VAL3	S2R_manager	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_VAL4	S2R_manager	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_VIG1	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_manager_VIG2	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_manager_VIG3	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_manager_VIG4	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_manager_CONF1	S2R_manager	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_FREQ1	S2R_manager	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_direct_report_E1	S2R_direct_report	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_A1	S2R_direct_report	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_C1	S2R_direct_report	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_N1	S2R_direct_report	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_O1	S2R_direct_report	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_E2	S2R_direct_report	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_direct_report_EI1	S2R_direct_report	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_EI2	S2R_direct_report	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_direct_report_SN1	S2R_direct_report	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_SN2	S2R_direct_report	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_direct_report_TF1	S2R_direct_report	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_direct_report_TF2	S2R_direct_report	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_JP1	S2R_direct_report	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_JP2	S2R_direct_report	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_direct_report_COM1	S2R_direct_report	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_COL1	S2R_direct_report	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_CRM1	S2R_direct_report	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_AVD1	S2R_direct_report	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_ACM1	S2R_direct_report	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_COL2	S2R_direct_report	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_PRO1	S2R_direct_report	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_PRO2	S2R_direct_report	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_PRO3	S2R_direct_report	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_PRO4	S2R_direct_report	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_VAL1	S2R_direct_report	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_VAL2	S2R_direct_report	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_VAL3	S2R_direct_report	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_VAL4	S2R_direct_report	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_VIG1	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_direct_report_VIG2	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_direct_report_VIG3	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_direct_report_VIG4	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S0_CHRONOTYPE	S0_profile	Relationship	Chronotype	Kronotip (Gün içinde en verimli olduğunuz zaman dilimi):	SingleChoice	Sabah|Akşam|Karışık	0	\N	1	\N	13
S2R_direct_report_CONF1	S2R_direct_report	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_FREQ1	S2R_direct_report	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_client_E1	S2R_client	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_A1	S2R_client	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_C1	S2R_client	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_N1	S2R_client	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_O1	S2R_client	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_E2	S2R_client	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_client_EI1	S2R_client	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_EI2	S2R_client	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_client_SN1	S2R_client	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_SN2	S2R_client	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_client_TF1	S2R_client	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_client_TF2	S2R_client	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_JP1	S2R_client	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_JP2	S2R_client	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_client_COM1	S2R_client	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_COL1	S2R_client	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_CRM1	S2R_client	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_AVD1	S2R_client	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_ACM1	S2R_client	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_COL2	S2R_client	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_PRO1	S2R_client	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_PRO2	S2R_client	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_PRO3	S2R_client	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_PRO4	S2R_client	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_VAL1	S2R_client	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_VAL2	S2R_client	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_VAL3	S2R_client	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_VAL4	S2R_client	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_VIG1	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_client_VIG2	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_client_VIG3	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_client_VIG4	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_client_CONF1	S2R_client	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_FREQ1	S2R_client	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_vendor_E1	S2R_vendor	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_A1	S2R_vendor	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_C1	S2R_vendor	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_N1	S2R_vendor	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_O1	S2R_vendor	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_E2	S2R_vendor	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_vendor_EI1	S2R_vendor	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_EI2	S2R_vendor	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_vendor_SN1	S2R_vendor	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_SN2	S2R_vendor	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_vendor_TF1	S2R_vendor	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_vendor_TF2	S2R_vendor	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_JP1	S2R_vendor	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_JP2	S2R_vendor	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_vendor_COM1	S2R_vendor	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_COL1	S2R_vendor	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_CRM1	S2R_vendor	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_AVD1	S2R_vendor	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_ACM1	S2R_vendor	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_COL2	S2R_vendor	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_PRO1	S2R_vendor	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_PRO2	S2R_vendor	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_PRO3	S2R_vendor	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_PRO4	S2R_vendor	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_VAL1	S2R_vendor	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_VAL2	S2R_vendor	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_VAL3	S2R_vendor	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_VAL4	S2R_vendor	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S0_TIME_BUDGET_HRS	S0_profile	Relationship	TimeBudget	İlişkilere ayırabildiğiniz zaman (haftalık saat):	Number		0	\N	1	\N	14
S2R_vendor_VIG1	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_vendor_VIG2	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_vendor_VIG3	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_vendor_VIG4	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_vendor_CONF1	S2R_vendor	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_FREQ1	S2R_vendor	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_mentor_E1	S2R_mentor	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_A1	S2R_mentor	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_C1	S2R_mentor	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_N1	S2R_mentor	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_O1	S2R_mentor	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_E2	S2R_mentor	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentor_EI1	S2R_mentor	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_EI2	S2R_mentor	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentor_SN1	S2R_mentor	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_SN2	S2R_mentor	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentor_TF1	S2R_mentor	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentor_TF2	S2R_mentor	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_JP1	S2R_mentor	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_JP2	S2R_mentor	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentor_COM1	S2R_mentor	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_COL1	S2R_mentor	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_CRM1	S2R_mentor	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_AVD1	S2R_mentor	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_ACM1	S2R_mentor	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_COL2	S2R_mentor	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_PRO1	S2R_mentor	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_PRO2	S2R_mentor	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_PRO3	S2R_mentor	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_PRO4	S2R_mentor	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_VAL1	S2R_mentor	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_VAL2	S2R_mentor	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_VAL3	S2R_mentor	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_VAL4	S2R_mentor	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_VIG1	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentor_VIG2	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentor_VIG3	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentor_VIG4	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentor_CONF1	S2R_mentor	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_FREQ1	S2R_mentor	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_mentee_E1	S2R_mentee	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_A1	S2R_mentee	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_C1	S2R_mentee	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_N1	S2R_mentee	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_O1	S2R_mentee	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_E2	S2R_mentee	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentee_EI1	S2R_mentee	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_EI2	S2R_mentee	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentee_SN1	S2R_mentee	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_SN2	S2R_mentee	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentee_TF1	S2R_mentee	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentee_TF2	S2R_mentee	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_JP1	S2R_mentee	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_JP2	S2R_mentee	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentee_COM1	S2R_mentee	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_COL1	S2R_mentee	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_CRM1	S2R_mentee	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_AVD1	S2R_mentee	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_ACM1	S2R_mentee	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_COL2	S2R_mentee	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_PRO2	S2R_mentee	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_PRO3	S2R_mentee	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_PRO4	S2R_mentee	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_VAL1	S2R_mentee	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_VAL2	S2R_mentee	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_VAL3	S2R_mentee	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_VAL4	S2R_mentee	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_VIG1	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentee_VIG2	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentee_VIG3	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentee_VIG4	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentee_CONF1	S2R_mentee	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_FREQ1	S2R_mentee	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S3_EI_1	S3_self	MBTI	EI	Yoğun bir günün sonunda enerjimi yenilemek için: A) insanlarla vakit geçiririm B) yalnız kalırım	ForcedChoice2	A|B	0	{"A": "E", "B": "I"}	1	\N	\N
S3_EI_2	S3_self	MBTI	EI	Yeni bir ortama girdiğimde: A) hızlıca kaynaşırım B) önce gözlemler sonra dahil olurum	ForcedChoice2	A|B	0	{"A": "E", "B": "I"}	1	\N	\N
S3_EI_3	S3_self	MBTI	EI	Beyin fırtınasında: A) yüksek sesle düşünürüm B) önce zihnimde netleştiririm	ForcedChoice2	A|B	0	{"A": "E", "B": "I"}	1	\N	\N
S3_SN_1	S3_self	MBTI	SN	Bir projeyi tartışırken önce: A) somut detay/kanıt B) büyük resim/olasılık	ForcedChoice2	A|B	0	{"A": "S", "B": "N"}	1	\N	\N
S3_SN_2	S3_self	MBTI	SN	Bir konuyu anlamak için: A) mevcut gerçekler B) olası senaryolar	ForcedChoice2	A|B	0	{"A": "S", "B": "N"}	1	\N	\N
S3_SN_3	S3_self	MBTI	SN	Yenilik karşısında: A) işe yararlık B) potansiyel fırsat	ForcedChoice2	A|B	0	{"A": "S", "B": "N"}	1	\N	\N
S3_TF_1	S3_self	MBTI	TF	Zor bir kararda: A) tutarlılık/adalet B) duygusal etki	ForcedChoice2	A|B	0	{"A": "T", "B": "F"}	1	\N	\N
S3_TF_2	S3_self	MBTI	TF	Geri bildirim verirken: A) net/doğrudan B) hissi gözeterek	ForcedChoice2	A|B	0	{"A": "T", "B": "F"}	1	\N	\N
S3_TF_3	S3_self	MBTI	TF	Çatışmada: A) problemi mantıkla çözerim B) duygusal etkiyi önce ele alırım	ForcedChoice2	A|B	0	{"A": "T", "B": "F"}	1	\N	\N
S3_JP_1	S3_self	MBTI	JP	Planlar: A) net takvim/kapalı uçlu B) seçenekler açık/akışkan	ForcedChoice2	A|B	0	{"A": "J", "B": "P"}	1	\N	\N
S3_JP_2	S3_self	MBTI	JP	Son dakika değişimi: A) rahatsız eder B) esnek davranırım	ForcedChoice2	A|B	0	{"A": "J", "B": "P"}	1	\N	\N
S3_JP_3	S3_self	MBTI	JP	Görev stili: A) bitişten önce tamamlarım B) son ana kadar seçenekler açık	ForcedChoice2	A|B	0	{"A": "J", "B": "P"}	1	\N	\N
S4_family_1	S4_family	ValuesBoundaries	BOUND	Aile içinde kişisel mahremiyete saygı önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_2	S4_family	ValuesBoundaries	COMM	Zor konuları sakin bir dille konuşabilmeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_3	S4_family	ValuesBoundaries	ROLE	Ev içi roller net olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_4	S4_family	ValuesBoundaries	SUPPORT	Duygusal destek göstermek değerlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_5	S4_family	ValuesBoundaries	BOUND	Özel eşyaları izinsiz kullanmak kabul edilemez.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_6	S4_family	ValuesBoundaries	COMM	Eleştiride kırıcı olmamaya özen gösterilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_7	S4_family	ValuesBoundaries	DECISION	Önemli kararlar ortak alınmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_8	S4_family	ValuesBoundaries	TIME	Aile zamanı için düzenli vakit ayırmak önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_9	S4_family	ValuesBoundaries	CONFLICT	Gerilimde kısa mola verip yeniden konuşabilmeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_10	S4_family	ValuesBoundaries	RESPECT	Kuşak farkı olsa da saygı korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_11	S4_family	ValuesBoundaries	FINANCE	Hane içi harcamalarda şeffaflık gerekir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_12	S4_family	ValuesBoundaries	BOUND	Misafir/ziyaret planında önceden haber verilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_13	S4_family	ValuesBoundaries	SUPPORT	Krizde ulaşılabilir olmak önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_14	S4_family	ValuesBoundaries	INDEP	Bağımsızlık alanına saygı duyulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_15	S4_family	ValuesBoundaries	DIGI	Dijital/telefon gizliliği gözetilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_16	S4_family	ValuesBoundaries	PRIV	Aile sırları üçüncü kişilerle paylaşılmamalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_17	S4_family	ValuesBoundaries	CARE	Hassas konular (sağlık vb.) özenle konuşulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_18	S4_family	ValuesBoundaries	FAIR	Sorumluluklar adil paylaşılmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_19	S4_family	ValuesBoundaries	BOUND	Ses yükseltmek sınır ihlalidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_20	S4_family	ValuesBoundaries	REPAIR	Kırgınlıkta özür ve onarım beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_1	S4_friend	ValuesBoundaries	BOUND	Plan değişikliğinde zamanında haber verilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_2	S4_friend	ValuesBoundaries	TRUST	Sırlar gizli tutulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_3	S4_friend	ValuesBoundaries	TIME	Düzenli görüşmeye önem veririm.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_4	S4_friend	ValuesBoundaries	FUN	Ortak aktivite planlamayı severim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_5	S4_friend	ValuesBoundaries	RESPECT	İğneleyici şakalardan kaçınılmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_6	S4_friend	ValuesBoundaries	SUPPORT	Zor günde mesaj/arayış beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_7	S4_friend	ValuesBoundaries	BOUND	Özel hayatımın sınırlarına saygı gösterilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_8	S4_friend	ValuesBoundaries	COMM	Sorunları açık ve sakin konuşabilmeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_9	S4_friend	ValuesBoundaries	FAIR	Harcama paylaşımında adalet önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_10	S4_friend	ValuesBoundaries	DIGI	Ekran görüntülerimi izinsiz paylaşmak kabul edilemez.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_11	S4_friend	ValuesBoundaries	RELIAB	Verilen sözlerin tutulması gerekir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_12	S4_friend	ValuesBoundaries	CONFLICT	Tartışmayı kaçırmadan çözüme odaklanmalıyız.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_13	S4_friend	ValuesBoundaries	FEED	Geri bildirimi iyi niyetle vermeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_14	S4_friend	ValuesBoundaries	PRIOR	Öncelikler çatıştığında açık iletişim beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_15	S4_friend	ValuesBoundaries	BOUND	Rızam olmadan eşyalarım kullanılmamalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_16	S4_friend	ValuesBoundaries	BAL	Karşılıklılık dengesi önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_17	S4_friend	ValuesBoundaries	REPAIR	Kırgınlık sonrası onarım beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_18	S4_friend	ValuesBoundaries	TIME	Son dakika iptalleri minimum olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_19	S4_friend	ValuesBoundaries	TRUST	Gıyabımda saygılı konuşulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_20	S4_friend	ValuesBoundaries	SUPPORT	Başarılarımı takdir etmesini beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_1	S4_work	ValuesBoundaries	PRO	Profesyonel sınırlara özen gösterilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_2	S4_work	ValuesBoundaries	COMM	Geri bildirim açık ve saygılı verilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_3	S4_work	ValuesBoundaries	OWN	Sorumluluk üstlenmek ve takip önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_4	S4_work	ValuesBoundaries	ALIGN	Ekip hedefleriyle hizalanma gereklidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_5	S4_work	ValuesBoundaries	TIME	Toplantı ve teslim tarihlerine uyum esastır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_6	S4_work	ValuesBoundaries	TRUST	Bilgi gizliliği korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_7	S4_work	ValuesBoundaries	BOUND	Mesai dışı yazışmalara makul sınır getirilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_8	S4_work	ValuesBoundaries	FAIR	İş yükü adil dağıtılmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_9	S4_work	ValuesBoundaries	CONFLICT	Uyuşmazlıklar kişiselleştirilmeden ele alınmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_10	S4_work	ValuesBoundaries	RESPECT	Hiyerarşi olsa da saygı korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_11	S4_work	ValuesBoundaries	FEED	Net hedef ve beklenti belirlenmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_12	S4_work	ValuesBoundaries	REPAIR	Hata sonrası onarım/öğrenme beklenir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_13	S4_work	ValuesBoundaries	OWN	Hatalarda sorumluluk almak değerlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_14	S4_work	ValuesBoundaries	BOUND	Kişisel konular iş ortamında sınırında kalmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_15	S4_work	ValuesBoundaries	ALIGN	Kararlar şeffaf iletişilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_16	S4_work	ValuesBoundaries	TRUST	Krediyi hakkaniyetle paylaşmak gerekir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_17	S4_work	ValuesBoundaries	TIME	Fazla mesai beklentisi şeffaf olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_18	S4_work	ValuesBoundaries	PRO	Toplantıda söz kesmemek önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_19	S4_work	ValuesBoundaries	COMM	E-posta/mesaj tonuna dikkat edilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_20	S4_work	ValuesBoundaries	SAFETY	Psikolojik güvenlik korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_1	S4_romantic	ValuesBoundaries	BOUND	Özel alan ve kişisel zamana saygı beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_2	S4_romantic	ValuesBoundaries	FINANCE	Maddi konularda şeffaflık isterim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_3	S4_romantic	ValuesBoundaries	COMM	Duyguların düzenli ifade edilmesini isterim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_4	S4_romantic	ValuesBoundaries	DIGI	Sosyal medyada mahremiyete dikkat edilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_5	S4_romantic	ValuesBoundaries	LOYAL	Sadakat kırmızı çizgimdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_6	S4_romantic	ValuesBoundaries	TRUST	Güven inşası için tutarlı davranış beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_7	S4_romantic	ValuesBoundaries	TIME	Kaliteli birlikte zaman önceliklidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_8	S4_romantic	ValuesBoundaries	SEX	Rıza ve sınırlar açık konuşulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_9	S4_romantic	ValuesBoundaries	REPAIR	Kırgınlıkta özür ve telafi beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_10	S4_romantic	ValuesBoundaries	BOUND	Kıskançlık kontrolü ve iletişimle yönetilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_11	S4_romantic	ValuesBoundaries	FAIR	Ev/ilişki sorumlulukları adil bölüşülmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_12	S4_romantic	ValuesBoundaries	FAM	Aile/arkadaş etkisi makul sınırda kalmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_13	S4_romantic	ValuesBoundaries	COMM	Tartışmada ses yükseltmek sınır ihlalidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_14	S4_romantic	ValuesBoundaries	PLAN	Gelecek planlarında fikirlerime değer verilmeli.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_15	S4_romantic	ValuesBoundaries	DIGI	Konum/mesaj denetimi talebi kabul edilemez.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_16	S4_romantic	ValuesBoundaries	SUPPORT	Zor günlerde yanında olmasını beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_17	S4_romantic	ValuesBoundaries	FUN	Birlikte keyifli rutini sürdürmek isterim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_18	S4_romantic	ValuesBoundaries	BOUND	Flört/iletişim sınırları net olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_19	S4_romantic	ValuesBoundaries	TRUST	Şeffaflık ve dürüstlük esastır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_20	S4_romantic	ValuesBoundaries	REPAIR	İlişki sorunlarında profesyonel destek opsiyonu açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S0_VALUES_TOP3	S0_profile	Values	Top3	Öncelikli değerlerim (en fazla 3 seçiniz):	MultiSelect	Dürüstlük|Sadakat|Özgürlük|Adalet|Başarı|Şefkat|Düzen|Yaratıcılık|Macera|Güvenlik|Saygı	0	\N	1	Maksimum 3 önerilir.	24
S0_MONEY_TALK_EASE	S0_profile	Values	MoneyTalk	Para/sorumluluk konuşma rahatlığım:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	\N	25
S0_SOCIAL_VIS_EASE	S0_profile	Values	SocialVisibility	Sosyal medya görünürlüğü rahatlığım:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	\N	26
S0_SUPPORT_SIZE	S0_profile	Support	Circle	Yakın destek halkası (kişi sayısı):	Number		0	\N	1	\N	27
S0_LOVE_LANG_ORDER	S0_profile	Romantic	LoveLangs	Sevgi dillerim (öncelik sırası—seçim sırasına göre):	RankedMulti	Onay sözleri|Kaliteli zaman|Hizmet|Hediye|Temas	0	\N	1	Sadece romantik bağlamda gösterin.	29
S0_TOUCH_COMFORT	S0_profile	Romantic	TouchComfort	Fiziksel temas rahatlığım:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	Sadece romantik bağlamda gösterin.	30
S0_CONSENT	S0_profile	Consent	Use	Analiz ve koçluk için verdiğim bilgilerin işlenmesini onaylıyorum.	SingleChoice	Evet|Hayır	0	\N	1	\N	31
S0_LIKES	S0_profile	Preferences	Likes	Sevdiğiniz şeyler (aktiviteler insanlar ortamlar):	OpenText		0	\N	1	Örn: Açık havada vakit geçirmek, derin sohbetler, yeni yerler keşfetmek...	16
S0_DISLIKES	S0_profile	Preferences	Dislikes	Sevmediğiniz / kaçındığınız şeyler:	OpenText		0	\N	1	Örn: Gürültülü ortamlar, geç kalınması, yalan söylenmesi...	17
S0_REL_GOALS	S0_profile	Goals	RelGoals	İlişkilerde kısa/orta vadeli hedefleriniz:	OpenText		0	\N	1	Örn: Daha iyi iletişim kurmak, güven inşa etmek, sınırları belirlemek...	19
S0_BOUNDARIES	S0_profile	Goals	Boundaries	Sınırlarınız / kırmızı çizgileriniz:	OpenText		0	\N	1	Örn: Yalan, aldatma, saygısızlık, şiddet...	20
S0_TOP_CHALLENGES	S0_profile	Challenges	TopChallenges	Sizi şu an en çok zorlayan konular:	OpenText		0	\N	1	Örn: İş yükü, aile ilişkileri, maddi konular, sağlık...	21
S0_NEAR_TERM	S0_profile	Challenges	NearTerm	Yakın zamanda çözmeniz gereken güçlük(ler):	OpenText		0	\N	1	Örn: Yeni iş bulma, taşınma, borç ödeme, sınav hazırlık...	22
S0_TRIGGERS	S0_profile	Challenges	Triggers	Bilinen çatışma tetikleyicilerim:	OpenText		0	\N	1	Örn: Alaycı üslup, eleştiri, plansızlık, ses tonu...	23
S0_COPING	S0_profile	Support	Coping	Sık kullandığım başa çıkma stratejileri:	OpenText		0	\N	1	Örn: Yürüyüş, meditasyon, müzik dinleme, arkadaşlarla konuşma...	28
S0_WHY_NEED	S0_profile	Consent	WhyNeed	Bu uygulamaya neden ihtiyaç duydunuz? (Anket amaçlı değil sizi tanımak ve ihtiyaçlarınızı anlamak için)	OpenText		0	\N	1	Örn: İlişkilerimi geliştirmek, kendimi tanımak, çatışmaları çözmek istiyorum...	32
S0_AGE	S0_profile	Demographics	Age	Yaşınız (sayı olarak):	Number		0	\N	1	\N	1
S0_GENDER	S0_profile	Demographics	Gender	Cinsiyetiniz (opsiyonel):	SingleChoice	Kadın|Erkek|Diğer|Belirtmek istemiyorum	0	\N	1	\N	2
S0_WORK_STATUS	S0_profile	EducationWork	WorkStatus	Şu an çalışma durumunuz:	SingleChoice	Çalışıyorum|Çalışmıyorum|İş arıyorum|Serbest	0	\N	1	\N	3
S0_STUDY_ACTIVE	S0_profile	EducationWork	StudyActive	Öğrenim durumunuz:	SingleChoice	Okuyorum|Okumuyorum	0	\N	1	\N	4
S0_SCHOOL_TYPE	S0_profile	EducationWork	SchoolType	Son/Güncel okul türü:	SingleChoice	Lise|Ön lisans|Lisans (Üniversite)|Yüksek Lisans|Doktora|Diğer	0	\N	1	Etiket: Okuyorum→Güncel okul; Okumuyorum→Son mezun olunan okul	5
S0_WORK_PACE	S0_profile	EducationWork	Pace	Çalışma/okul temposu:	SingleChoice	Düzenli mesai|Vardiya|Serbest|Yoğun dönemli	0	\N	1	\N	7
S0_STRESS_NOW	S0_profile	EducationWork	Stress	Güncel stres düzeyim:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	\N	8
S0_COMMUTE_MIN	S0_profile	EducationWork	Commute	Günlük yol/lojistik yük (dakika):	Number		0	\N	1	Opsiyonel	9
S0_REL_STATUS	S0_profile	Relationship	Status	Medeni/İlişki durumunuz:	SingleChoice	Bekâr|İlişkim var|Nişanlı|Evli|Ayrı yaşıyorum|Boşanmış|Diğer	0	\N	1	\N	10
S0_LIVE_WITH	S0_profile	Relationship	Household	Birlikte yaşadıklarım:	MultiSelect	Yalnız|Ailemle|Ev arkadaşı|Partner|Çocuk(lar)|Bakımını üstlendiğim biri	0	\N	1	\N	11
S0_CARE_DUTIES	S0_profile	Relationship	Care	Bakım sorumluluğu:	MultiSelect	Çocuk|Yaşlı yakını|Engelli yakını|Evcil hayvan|Yok	0	\N	1	\N	12
S0_SCHOOL_FIELD	S0_profile	EducationWork	SchoolField	Bölüm/Alan:	OpenText		0	\N	1	Örn: Bilgisayar Mühendisliği, İşletme, Tıp, Hukuk...	6
S0_HOBBIES	S0_profile	Preferences	Hobbies	Hobileriniz / ilgi alanlarınız:	OpenText		0	\N	1	Örn: Kitap okuma, yüzme, müzik, doğa yürüyüşü, yemek yapma...	15
S0_LIFE_GOAL	S0_profile	Goals	LifePurpose	Hayattaki amacınız / yönünüz:	OpenText		0	\N	1	Örn: İnsanlara yardım etmek, sürekli öğrenmek, aileme iyi bir hayat sağlamak...	18
S1_DISC_SJT1	S1_self	DISC	DISC	Evde acil karar gerektiren bir durum var (örn. su sızıntısı); ilk tutumunuz?	MultiChoice4	Ana vanayı kapatır, ustayı arar, gerekirse komşuyu bilgilendiririm.|Mahalle/WhatsApp grubunda yardım çağırır, çevreyi hızla organize ederim.|Evdeki herkesin sakin olduğundan emin olur, görevleri paylaşarak destek olurum.|Kaynağı kontrol eder, foto/video ile durumu belgeleyip sigorta/yönetimle prosedürü başlatırım.	0	\N	1	\N	70
S1_DISC_SJT3	S1_self	DISC	DISC	Aldığınız üründe sorun çıktı; ilk odağınız?	MultiChoice4	Satıcıyla hemen iletişime geçip değişim/iade talep ederim.|Müşteri temsilcisiyle olumlu bir diyalog kurup çözümü hızlandırırım.|Yakın çevreme danışıp birlikte en pratik adımı atarım.|Fatura/garanti ve arıza notlarını toplayıp üretici kılavuzuna göre ilerlerim.	0	\N	1	\N	72
S1_DISC_SJT4	S1_self	DISC	DISC	Plan dışı değişiklik talebi geldi (örn. tatil rotası); refleksiniz?	MultiChoice4	Yeni rotayı hızla belirleyip programa geçiririm.|Değişikliğin cazibesini anlatarak grubu ikna ederim.|Herkesin rahat edeceği orta yolu bulmak için öneri toplarım.|Alternatifleri süre/maliyet/riske göre kısa karşılaştırır, veriye dayalı öneri getiririm.	0	\N	1	\N	73
S1_DISC_SJT6	S1_self	DISC	DISC	Yakın çevrede moral düşük (ör. arkadaş üzgün); ilk hamleniz?	MultiChoice4	Pratik çözüm seçenekleri çıkarır, küçük bir aksiyon planı yaparım.|Moral yükselten bir sohbet/aktivite organize ederim.|Yanında sakince bulunur, dinler ve duygusal destek veririm.|Durumu sistematik değerlendirir, uygun kaynak/uzman öneririm.	0	\N	1	\N	75
S1_DISC_SJT7	S1_self	DISC	DISC	Aynı zamana denk gelen aile ve arkadaş planları çakıştı; yaklaşımınız?	MultiChoice4	Önceliklendirme yapar, net bir karar verip birini iptal ederim.|Herkese yazıp esnek, yeni ortak bir zaman bulmaya çalışırım.|Kimseyi kırmamak için kısa süreli/ardışık katılım planlarım.|Takvim/lojistik analiz yapar, en verimli seçeneği seçerim.	0	\N	1	\N	76
S1_DISC_SJT9	S1_self	DISC	DISC	Komşudan gece geç saatte yüksek ses geliyor; ilk yaklaşımınız ne olur?	MultiChoice4	Kapısını çalar, netçe rahatsızlığı iletip sesin kısılmasını isterim.|Site/WhatsApp grubunda kibar bir mesajla konuyu anlatır, destek isterim.|Sabah uygun bir zamanda sakin bir dille konuşmayı teklif ederim.|Site kuralları/yönetmeliği kontrol edip uygun kanaldan resmi bildirim yaparım.	0	\N	1	\N	78
S1_DISC_SJT10	S1_self	DISC	DISC	Ortak kullanılan ev/mutfakta bulaşıklar birikiyor; nasıl ilerlersiniz?	MultiChoice5	Bundan sonra kuralları ben koyarım; herkes uysun.|Birlikte küçük bir plan yapalım (takvim, görev paylaşımı).|Herkes biraz taviz versin; bugün ben hallederim, yarın siz.|Şimdilik görmezden gelelim; uygun zamanda konuşuruz.|Ben hallederim; siz nasıl rahatsanız öyle olsun.	0	\N	1	\N	79
\.


--
-- Data for Name: language_incidents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.language_incidents (id, user_id, report_type, user_language, detected_language, content_preview, created_at) FROM stdin;
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, session_id, role, content, created_at) FROM stdin;
\.


--
-- Data for Name: monthly_usage_summary; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.monthly_usage_summary (id, user_id, subscription_id, month_year, self_analysis_count, self_reanalysis_count, other_analysis_count, relationship_analysis_count, coaching_tokens_used, total_cost_usd, total_charged_usd, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: payg_pricing; Type: TABLE DATA; Schema: public; Owner: postgres
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
-- Data for Name: payg_purchases; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payg_purchases (id, user_id, service_type, quantity, unit_price, total_price, payment_status, payment_method, transaction_id, created_at, updated_at, iap_transaction_id) FROM stdin;
\.


--
-- Data for Name: people; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.people (id, user_id, label, relation_type, gender, age, notes) FROM stdin;
\.


--
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reports (id, owner_user_id, dyad_id, markdown, version) FROM stdin;
\.


--
-- Data for Name: responses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.responses (id, assessment_id, item_id, value, rt_ms) FROM stdin;
\.


--
-- Data for Name: scores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scores (id, assessment_id, bigfive_json, mbti_json, enneagram_json, attachment_json, conflict_json, social_json, quality_flags) FROM stdin;
\.


--
-- Data for Name: subscription_plans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subscription_plans (id, name, self_analysis_limit, self_reanalysis_limit, other_analysis_limit, relationship_analysis_limit, coaching_tokens_limit, price_usd, is_active, created_at, updated_at) FROM stdin;
standard	Standart	1	2	8	8	200000000	20.00	t	2025-08-19 18:54:08.406793	2025-08-19 21:17:54.806216
extra	Extra	1	5	25	25	500000000	50.00	t	2025-08-19 18:54:08.406793	2025-08-19 21:17:54.831953
\.


--
-- Data for Name: token_costs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.token_costs (id, model_name, input_cost_per_1k, output_cost_per_1k, is_active, created_at, updated_at) FROM stdin;
gpt-4	gpt-4	0.030000	0.060000	t	2025-08-19 18:54:08.408226	2025-08-19 18:54:08.408226
gpt-4-turbo	gpt-4-turbo-preview	0.010000	0.030000	t	2025-08-19 18:54:08.408226	2025-08-19 18:54:08.408226
gpt-3.5-turbo	gpt-3.5-turbo	0.000500	0.001500	t	2025-08-19 18:54:08.408226	2025-08-19 18:54:08.408226
gpt-4o	gpt-4o	0.005000	0.015000	t	2025-08-19 18:54:08.408226	2025-08-19 18:54:08.408226
gpt-4o-mini	gpt-4o-mini	0.000150	0.000600	t	2025-08-19 18:54:08.408226	2025-08-19 18:54:08.408226
\.


--
-- Data for Name: usage_tracking; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usage_tracking (id, user_id, service_type, target_id, is_reanalysis, tokens_used, input_tokens, output_tokens, cost_usd, price_charged_usd, subscription_id, created_at) FROM stdin;
\.


--
-- Data for Name: user_lifecoaching_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_lifecoaching_notes (user_id, notes, created_at, updated_at) FROM stdin;
ebe6eee2-01ae-4753-9737-0983b0330880	{"do_not": [], "language": "tr", "routines": [], "timezone": null, "triggers": [], "boundaries": [], "coach_tone": "short, formal", "values_top3": [], "communication": {"contact_freq": "", "feedback_style": "", "preferred_channels": [], "privacy_expectation_level": 0}, "energy_rhythm": "", "top_strengths": [], "growth_targets": [], "checkin_cadence": "", "confidence_band": "low", "near_term_focus": [], "conflict_posture": "", "connection_style": "", "stress_level_now": 0, "summary_one_liner": "Bilinmezlikler ve eksik bilgilerle dolu bir değerlendirme.", "social_action_style": "", "soothing_strategies": [], "support_circle_size": 0, "time_budget_hours_weekly": 0}	2025-08-20 00:52:25.247366+03	2025-08-20 00:52:25.247366+03
\.


--
-- Data for Name: user_subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_subscriptions (id, user_id, plan_id, status, billing_cycle, start_date, end_date, created_at, updated_at, credits_used, credits_remaining, is_primary, iap_transaction_id) FROM stdin;
2dd37537-8a71-44aa-a22c-8722c0f9b524	ebe6eee2-01ae-4753-9737-0983b0330880	extra	active	monthly	2025-08-19 22:38:45.373423	2025-09-19 22:38:45.373423	2025-08-19 22:38:45.373423	2025-08-19 22:38:45.373423	{}	{"other_analysis": 25, "coaching_tokens": 500000000, "self_reanalysis": 5, "relationship_analysis": 25}	f	\N
bc822d05-6b7d-4d42-a7da-680c386882c7	ebe6eee2-01ae-4753-9737-0983b0330880	standard	active	monthly	2025-08-19 22:19:40.282202	2025-09-19 22:19:40.281	2025-08-19 22:19:40.282202	2025-08-19 22:41:11.695497	{}	{"other_analysis": 8, "coaching_tokens": 200000000, "self_reanalysis": 2, "relationship_analysis": 8}	f	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, locale, created_at) FROM stdin;
ebe6eee2-01ae-4753-9737-0983b0330880	test@test.com	tr	2025-08-19 20:39:47.570899+03
\.


--
-- Name: responses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.responses_id_seq', 1, false);


--
-- Name: analysis_results analysis_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analysis_results
    ADD CONSTRAINT analysis_results_pkey PRIMARY KEY (id);


--
-- Name: assessments assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (id);


--
-- Name: chat_sessions chat_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_sessions
    ADD CONSTRAINT chat_sessions_pkey PRIMARY KEY (id);


--
-- Name: dyad_scores dyad_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyad_scores
    ADD CONSTRAINT dyad_scores_pkey PRIMARY KEY (id);


--
-- Name: dyads dyads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyads
    ADD CONSTRAINT dyads_pkey PRIMARY KEY (id);


--
-- Name: iap_products iap_products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.iap_products
    ADD CONSTRAINT iap_products_pkey PRIMARY KEY (id);


--
-- Name: iap_products iap_products_platform_product_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.iap_products
    ADD CONSTRAINT iap_products_platform_product_id_key UNIQUE (platform, product_id);


--
-- Name: iap_purchases iap_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.iap_purchases
    ADD CONSTRAINT iap_purchases_pkey PRIMARY KEY (id);


--
-- Name: iap_purchases iap_purchases_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.iap_purchases
    ADD CONSTRAINT iap_purchases_transaction_id_key UNIQUE (transaction_id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: language_incidents language_incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.language_incidents
    ADD CONSTRAINT language_incidents_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: monthly_usage_summary monthly_usage_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_usage_summary
    ADD CONSTRAINT monthly_usage_summary_pkey PRIMARY KEY (id);


--
-- Name: monthly_usage_summary monthly_usage_summary_user_id_month_year_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_usage_summary
    ADD CONSTRAINT monthly_usage_summary_user_id_month_year_key UNIQUE (user_id, month_year);


--
-- Name: payg_pricing payg_pricing_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payg_pricing
    ADD CONSTRAINT payg_pricing_pkey PRIMARY KEY (id);


--
-- Name: payg_purchases payg_purchases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payg_purchases
    ADD CONSTRAINT payg_purchases_pkey PRIMARY KEY (id);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: responses responses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responses
    ADD CONSTRAINT responses_pkey PRIMARY KEY (id);


--
-- Name: scores scores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_pkey PRIMARY KEY (id);


--
-- Name: subscription_plans subscription_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription_plans
    ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (id);


--
-- Name: token_costs token_costs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.token_costs
    ADD CONSTRAINT token_costs_pkey PRIMARY KEY (id);


--
-- Name: usage_tracking usage_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usage_tracking
    ADD CONSTRAINT usage_tracking_pkey PRIMARY KEY (id);


--
-- Name: user_lifecoaching_notes user_lifecoaching_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_lifecoaching_notes
    ADD CONSTRAINT user_lifecoaching_notes_pkey PRIMARY KEY (user_id);


--
-- Name: user_subscriptions user_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_analysis_results_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_analysis_results_created_at ON public.analysis_results USING btree (created_at DESC);


--
-- Name: idx_analysis_results_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_analysis_results_status ON public.analysis_results USING btree (status);


--
-- Name: idx_analysis_results_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_analysis_results_user_id ON public.analysis_results USING btree (user_id);


--
-- Name: idx_iap_transaction; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_iap_transaction ON public.iap_purchases USING btree (transaction_id);


--
-- Name: idx_iap_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_iap_user ON public.iap_purchases USING btree (user_id);


--
-- Name: idx_lifecoaching_notes_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lifecoaching_notes_user_id ON public.user_lifecoaching_notes USING btree (user_id);


--
-- Name: idx_monthly_usage_user_month; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_monthly_usage_user_month ON public.monthly_usage_summary USING btree (user_id, month_year);


--
-- Name: idx_payg_purchases_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payg_purchases_user_id ON public.payg_purchases USING btree (user_id);


--
-- Name: idx_people_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_people_user ON public.people USING btree (user_id);


--
-- Name: idx_resp_assessment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resp_assessment ON public.responses USING btree (assessment_id);


--
-- Name: idx_resp_item; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resp_item ON public.responses USING btree (item_id);


--
-- Name: idx_usage_tracking_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usage_tracking_created_at ON public.usage_tracking USING btree (created_at);


--
-- Name: idx_usage_tracking_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usage_tracking_user_id ON public.usage_tracking USING btree (user_id);


--
-- Name: idx_user_subscriptions_end_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_subscriptions_end_date ON public.user_subscriptions USING btree (end_date);


--
-- Name: idx_user_subscriptions_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_subscriptions_status ON public.user_subscriptions USING btree (status);


--
-- Name: idx_user_subscriptions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_subscriptions_user_id ON public.user_subscriptions USING btree (user_id);


--
-- Name: usage_tracking trigger_update_monthly_usage; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_update_monthly_usage AFTER INSERT ON public.usage_tracking FOR EACH ROW EXECUTE FUNCTION public.update_monthly_usage();


--
-- Name: usage_tracking update_monthly_usage_on_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_monthly_usage_on_insert AFTER INSERT ON public.usage_tracking FOR EACH ROW EXECUTE FUNCTION public.update_monthly_usage_summary();


--
-- Name: analysis_results analysis_results_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analysis_results
    ADD CONSTRAINT analysis_results_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: assessments assessments_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: chat_sessions chat_sessions_dyad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_sessions
    ADD CONSTRAINT chat_sessions_dyad_id_fkey FOREIGN KEY (dyad_id) REFERENCES public.dyads(id) ON DELETE CASCADE;


--
-- Name: dyad_scores dyad_scores_dyad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyad_scores
    ADD CONSTRAINT dyad_scores_dyad_id_fkey FOREIGN KEY (dyad_id) REFERENCES public.dyads(id) ON DELETE CASCADE;


--
-- Name: dyads dyads_a_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyads
    ADD CONSTRAINT dyads_a_person_id_fkey FOREIGN KEY (a_person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: dyads dyads_b_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyads
    ADD CONSTRAINT dyads_b_person_id_fkey FOREIGN KEY (b_person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: user_subscriptions fk_iap_transaction; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT fk_iap_transaction FOREIGN KEY (iap_transaction_id) REFERENCES public.iap_purchases(transaction_id);


--
-- Name: payg_purchases fk_payg_iap_transaction; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payg_purchases
    ADD CONSTRAINT fk_payg_iap_transaction FOREIGN KEY (iap_transaction_id) REFERENCES public.iap_purchases(transaction_id);


--
-- Name: iap_purchases iap_purchases_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.iap_purchases
    ADD CONSTRAINT iap_purchases_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: language_incidents language_incidents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.language_incidents
    ADD CONSTRAINT language_incidents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: messages messages_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.chat_sessions(id) ON DELETE CASCADE;


--
-- Name: monthly_usage_summary monthly_usage_summary_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_usage_summary
    ADD CONSTRAINT monthly_usage_summary_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.user_subscriptions(id);


--
-- Name: monthly_usage_summary monthly_usage_summary_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_usage_summary
    ADD CONSTRAINT monthly_usage_summary_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: people people_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reports reports_dyad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_dyad_id_fkey FOREIGN KEY (dyad_id) REFERENCES public.dyads(id) ON DELETE CASCADE;


--
-- Name: reports reports_owner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: responses responses_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responses
    ADD CONSTRAINT responses_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: responses responses_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responses
    ADD CONSTRAINT responses_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: scores scores_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: usage_tracking usage_tracking_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usage_tracking
    ADD CONSTRAINT usage_tracking_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.user_subscriptions(id);


--
-- Name: usage_tracking usage_tracking_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usage_tracking
    ADD CONSTRAINT usage_tracking_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_lifecoaching_notes user_lifecoaching_notes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_lifecoaching_notes
    ADD CONSTRAINT user_lifecoaching_notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_subscriptions user_subscriptions_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.subscription_plans(id);


--
-- Name: user_subscriptions user_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_subscriptions
    ADD CONSTRAINT user_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

