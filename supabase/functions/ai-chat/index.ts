/// <reference types="https://deno.land/x/deno/cli/types/deno.d.ts" />
import "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

// DeepSeek API configuration
const DEEPSEEK_API_KEY = Deno.env.get("DEEPSEEK_API_KEY") || "";
const DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions";

// Supabase configuration (service role for database operations)
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

Deno.serve(async (req: Request) => {
  // Handle CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Check API key
    if (!DEEPSEEK_API_KEY) {
      return new Response(
        JSON.stringify({
          error: "DEEPSEEK_API_KEY not configured",
          choices: [
            {
              message: {
                content:
                  "Error: La API key de DeepSeek no está configurada. Por favor configura la variable DEEPSEEK_API_KEY en Supabase.",
              },
            },
          ],
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const body = await req.json();
    const { messages, temperature = 0.7, max_tokens = 500, user_id } = body;

    console.log("🚀 Calling DeepSeek API...");
    console.log("📝 Messages count:", messages?.length || 0);

    // Call DeepSeek API
    const response = await fetch(DEEPSEEK_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${DEEPSEEK_API_KEY}`,
      },
      body: JSON.stringify({
        model: "deepseek-chat",
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens,
      }),
    });

    console.log("📡 DeepSeek response status:", response.status);

    if (!response.ok) {
      const errorText = await response.text();
      console.error("❌ DeepSeek API error:", errorText);
      return new Response(
        JSON.stringify({
          error: `DeepSeek API error: ${response.status}`,
          choices: [
            {
              message: {
                content: `Error del API de DeepSeek (${response.status}). Por favor intenta de nuevo.`,
              },
            },
          ],
        }),
        {
          status: response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const data = await response.json();
    console.log("✅ DeepSeek response received");

    // 🎯 AGENT LOGIC: Handle reservation creation
    if (data.choices && data.choices[0]?.message?.content) {
      const aiContent = data.choices[0].message.content;
      
      // Check for reservation action
      const actionMatch = aiContent.match(/\[ACTION:BOOK_SERVICE\|([^\]]+)\]/);
      if (actionMatch) {
        console.log("🎫 [AGENT] Detected reservation request");
        
        const actionParts = actionMatch[1].split("|");
        const serviceId = actionParts[0];
        const date = actionParts[1];
        const time = actionParts[2];
        const address = actionParts[3];
        
        console.log("🎫 [AGENT] Reservation details:", { serviceId, date, time, address, user_id });
        
        if (serviceId && date && time && address && user_id && SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY) {
          try {
            // Create Supabase client with service role
            const supabase = (globalThis as any).supabase.createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
              auth: {
                autoRefreshToken: false,
                persistSession: false,
              },
            });
            
            // Fetch service details
            const { data: service, error: serviceError } = await supabase
              .from("services")
              .select("*, providers(name, phone, image_url)")
              .eq("id", serviceId)
              .single();
            
            if (serviceError || !service) {
              console.error("❌ [AGENT] Service not found:", serviceError);
              data.choices[0].message.content = aiContent.replace(
                actionMatch[0],
                ""
              ) + "\n\n⚠️ Lo siento, no pude encontrar el servicio seleccionado. Por favor intenta de nuevo.";
            } else {
              // 🛡️ VALIDACIÓN 1: Verificar que el servicio esté activo
              if (service.is_active === false) {
                console.error("❌ [AGENT] Service is not active:", serviceId);
                data.choices[0].message.content = aiContent.replace(
                  actionMatch[0],
                  ""
                ) + "\n\n⚠️ Este servicio no está disponible actualmente. Por favor elige otro servicio.";
                return new Response(JSON.stringify(data), {
                  status: 200,
                  headers: { ...corsHeaders, "Content-Type": "application/json" },
                });
              }

              // 🛡️ VALIDACIÓN 2: Verificar que la fecha sea futura
              const scheduledDateTime = new Date(`${date}T${time}`);
              const now = new Date();
              if (scheduledDateTime <= now) {
                console.error("❌ [AGENT] Date is in the past:", { date, time });
                data.choices[0].message.content = aiContent.replace(
                  actionMatch[0],
                  ""
                ) + "\n\n⚠️ La fecha y hora seleccionadas deben ser futuras. Por favor elige una fecha posterior.";
                return new Response(JSON.stringify(data), {
                  status: 200,
                  headers: { ...corsHeaders, "Content-Type": "application/json" },
                });
              }

              // 🛡️ VALIDACIÓN 3: Verificar disponibilidad del slot (no double-booking)
              const { data: existingReservations, error: checkError } = await supabase
                .from("reservations")
                .select("id")
                .eq("service_id", serviceId)
                .eq("scheduled_date", date)
                .eq("scheduled_time", time)
                .in("status", ["confirmed", "pending"])
                .limit(1);

              if (checkError) {
                console.error("❌ [AGENT] Error checking slot availability:", checkError);
              }

              if (existingReservations && existingReservations.length > 0) {
                console.error("❌ [AGENT] Slot already booked:", { serviceId, date, time });
                data.choices[0].message.content = aiContent.replace(
                  actionMatch[0],
                  ""
                ) + "\n\n⚠️ Este horario ya está reservado. Por favor elige otra fecha u hora.";
                return new Response(JSON.stringify(data), {
                  status: 200,
                  headers: { ...corsHeaders, "Content-Type": "application/json" },
                });
              }

              console.log("✅ [AGENT] All validations passed, creating reservation");

              // Create reservation
              const reservationId = crypto.randomUUID();
              const { error: insertError } = await supabase
                .from("reservations")
                .insert({
                  id: reservationId,
                  user_id: user_id,
                  service_id: serviceId,
                  service_name: service.title,
                  service_image_url: service.image_url,
                  provider_name: service.providers?.name || "Proveedor Asignado",
                  provider_phone: service.providers?.phone || "+51 999 999 999",
                  provider_image_url: service.providers?.image_url || 
                    `https://ui-avatars.com/api/?name=${encodeURIComponent(service.providers?.name || 'Provider')}&background=667EEA&color=fff`,
                  scheduled_date: date,
                  scheduled_time: time,
                  address: address,
                  status: "confirmed",
                  amount: service.price,
                  currency: service.currency || "S/",
                  is_paid: false,
                  booking_method: "ai_chat",
                  created_at: new Date().toISOString(),
                });
              
              if (insertError) {
                console.error("❌ [AGENT] Error creating reservation:", insertError);
                data.choices[0].message.content = aiContent.replace(
                  actionMatch[0],
                  ""
                ) + "\n\n❌ Lo siento, hubo un error al crear tu reserva. Por favor inténtalo de nuevo.";
              } else {
                console.log("✅ [AGENT] Reservation created successfully:", reservationId);
                // Modify response to confirm and remove action token
                data.choices[0].message.content = aiContent.replace(
                  actionMatch[0],
                  ""
                ) + `\n\n✅ ¡Reserva confirmada! ID: ${reservationId.slice(0, 8)}`;
                
                // Add reservation metadata to response
                data.reservation_created = true;
                data.reservation_id = reservationId;
              }
            }
          } catch (agentError) {
            console.error("❌ [AGENT] Unexpected error:", agentError);
            data.choices[0].message.content = aiContent.replace(
              actionMatch[0],
              ""
            ) + "\n\n❌ Error inesperado. Por favor contacta soporte.";
          }
        } else {
          console.log("⚠️ [AGENT] Missing required fields for reservation");
          if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
            console.error("❌ [AGENT] Missing Supabase configuration");
          }
          data.choices[0].message.content = aiContent.replace(
            actionMatch[0],
            ""
          ) + "\n\n⚠️ Faltan datos para completar la reserva.";
        }
      }
    }

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: any) {
    console.error("❌ Edge Function error:", error);
    return new Response(
      JSON.stringify({
        error: error.message,
        choices: [
          {
            message: {
              content:
                "Lo siento, hubo un error procesando tu solicitud. Por favor intenta de nuevo.",
            },
          },
        ],
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
