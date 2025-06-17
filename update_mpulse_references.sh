#!/usr/bin/env bash
set -euo pipefail

# Usage: ./update_mpulse_references.sh <domains_file> <api_token> <tenant> [<output_csv>]
# Example: ./update_mpulse_references.sh domains.txt "your_api_token" "your_tenant" results.csv

# Input arguments
if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <domains_file> <api_token> <tenant> [<output_csv>]"
  exit 1
fi

domains_file="$1"
api_token="$2"
tenant="$3"
output_csv="${4:-output.csv}"

# Ensure reference.json exists
if [[ ! -f "reference.json" ]]; then
  echo "Error: reference.json not found in current directory." >&2
  exit 1
fi

# Initialize CSV output with header
printf "domain,objectID,status\n" > "$output_csv"

# Function to URL-encode a string
urlencode() {
  printf '%s' "$1" | jq -s -R -r @uri
}

# Process each domain
while IFS= read -r domain || [[ -n "$domain" ]]; do
  [[ -z "$domain" ]] && continue
  echo "Processing domain: $domain"

  # URL-encode domain
  enc_domain=$(urlencode "$domain")
  list_url="https://mpulse.soasta.com/concerto/services/rest/RepositoryService/v1/Objects/domain?domain=${enc_domain}"

  # Step 1: GET object list
  raw_body=$(curl -sS \
    -H "X-Auth-Token: $api_token" \
    -H "X-Tenant-Name: $tenant" \
    "$list_url")
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "X-Auth-Token: $api_token" \
    -H "X-Tenant-Name: $tenant" \
    "$list_url")

  # Check for expected status
  if [[ "$http_code" != "200" && "$http_code" != "204" ]]; then
    echo "  ERROR: Step 1 failed for $domain (HTTP $http_code)"
    echo "  Response: $raw_body"
    printf "%s,,FAIL_STEP1_%s\n" "$domain" "$http_code" >> "$output_csv"
    continue
  fi

  # Validate objects array
  has_objects=$(echo "$raw_body" | jq -e 'has("objects") and (.objects | type == "array" and length > 0)' 2>/dev/null || echo "false")
  if [[ "$has_objects" != "true" ]]; then
    echo "  ⚠️ No objects array found or it's empty for $domain"
    printf "%s,,NO_OBJECTS_ARRAY\n" "$domain" >> "$output_csv"
    continue
  fi

  # Extract object ID
  object_id=$(echo "$raw_body" | jq -r '.objects[0].id')
  if [[ -z "$object_id" || "$object_id" == "null" ]]; then
    echo "  ⚠️ Object ID is empty for $domain"
    printf "%s,,NO_OBJECT_ID\n" "$domain" >> "$output_csv"
    continue
  fi

  echo "  → Found objectID: $object_id"

  # Step 2: Update reference
  update_url="https://mpulse.soasta.com/concerto/services/rest/RepositoryService/v1/Objects/domain/$object_id"
  status=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "X-Auth-Token: $api_token" \
    -H "X-Tenant-Name: $tenant" \
    -H "Content-Type: application/json" \
    --data @reference.json \
    "$update_url") || status="REQUEST_FAIL"

  echo "  → Update status: $status"
  printf "%s,%s,%s\n" "$domain" "$object_id" "$status" >> "$output_csv"
done < "$domains_file"

echo -e "\n✅ All done! See $output_csv for results."
