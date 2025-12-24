#!/bin/bash

# --- Configuration ---
READINGS_DIR="readings"
CSV_DATA_FILE="csv_data.txt"

# --- Core Data (Ensure csv_data.txt is in the same directory) ---
# The CSV data is read from the file: csv_data.txt.
# File structure (must match the content in csv_data.txt):
# Day,Old Testament,New Testament,"Psalms & Proverbs"
# 1,"...", "...", "..."

# --- Helper Function: Get Calendar Date and Leap Year Text ---
# Calculates the calendar date (Month Day) for a given reading Day (1-366)
# and generates the required conditional text for the file header.
# Arguments:
# $1: The reading day number (1-366)
function get_calendar_info() {
    local day_num=$1
    local non_leap_date non_leap_text leap_date_display leap_text=""

    # --- 1. Calculate Non-Leap Date (Jan 1 = Day 1) ---
    # Using %d instead of %-d for cross-platform compatibility.
    non_leap_date=$(date -d "Jan 1 + $((day_num - 1)) days" +"%B %d")

    # --- 2. Format Conditional Output Text ---

    if (( day_num <= 59 )); then
        # Case 1: Jan 1 - Feb 28. Dates are the same in both years.
        # We only need the simple sentence.
        echo "If your reading is aligned with the calendar year, this is for $non_leap_date"
        return

    elif (( day_num == 60 )); then
        # Case 2: Reading day 60 (corresponds to Feb 29 in a leap year).
        non_leap_text="If your reading is aligned with the calendar year in a non-leap-year, this is for March 01"
        leap_text="or, in a leap-year, for February 29"

    else
        # Case 3: March 1 onwards (Day 61+)

        # Non-Leap Date Display (uses the non-leap calendar day)
        non_leap_text="If your reading is aligned with the calendar year in a non-leap-year, this is for $non_leap_date"

        # Leap Date Display (shifted forward by one day)
        if (( day_num <= 365 )); then
            # Get the date that is one calendar day later (for the leap year shift)
            leap_date_ordinal=$((day_num + 1))
            leap_date_display=$(date -d "Jan 1 + $((leap_date_ordinal - 1)) days" +"%B %d")
            leap_text="or, in a leap-year, for $leap_date_display"
        else
            # Day 366 (Dec 31 in a leap year)
            leap_date_display="December 31"
            leap_text="or, in a leap-year, for $leap_date_display"
        fi
    fi

    # Final Output for Case 2 and Case 3 (Day 60+)
    # This structure is needed for the multi-line output (with the "---")
    echo -e "$non_leap_text\n--- $leap_text"
}

# --- Function to Generate a Single Reading File ---
# Arguments:
# $1: Day number
# $2: Old Testament Reading (comma-separated list of books/chapters)
# $3: New Testament Reading (comma-separated list of books/chapters)
# $4: Psalms & Proverbs Reading (comma-separated list of books/chapters)
function generate_reading_file() {
    local day_num="$1"
    local ot_reading="$2"
    local nt_reading="$3"
    local pp_reading="$4"

    local filename="${READINGS_DIR}/day_${day_num}.txt"

    # Get the conditional calendar date text
    local calendar_info=$(get_calendar_info "$day_num")

    # Clean up the book/chapter lists for individual verse output (replace comma with newline)
    # The sed command ensures any leading/trailing whitespace is removed from the parts.
    local ot_parts=$(echo "$ot_reading" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    local nt_parts=$(echo "$nt_reading" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    local pp_parts=$(echo "$pp_reading" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Start writing the file content
    echo "Creating $filename..."

    cat > "$filename" <<- EOL
#import "BIAY_Style.typ": *

// Take a look at the file \`BIAY_Style.typ\`
// to customize this template and discover how it works.
#show: project.with(
  title: "Bible In A Year"
)

= This is the reading for day $day_num

$calendar_info

== The Old Testament reading is from: $ot_reading

$ot_parts

== The New Testament reading is from: $nt_reading

$nt_parts

== The Wisdom Literature reading is from: $pp_reading

$pp_parts

=== This concludes the reading for day $day_num. Thank you for listening.
EOL

}

# --- Main Execution ---

# 1. Check for the data file
if [[ ! -f "$CSV_DATA_FILE" ]]; then
    echo "ERROR: Data file '$CSV_DATA_FILE' not found." >&2
    echo "Please ensure the file is in the same directory as this script." >&2
    exit 1
fi

# 2. Create the readings directory
if [[ ! -d "$READINGS_DIR" ]]; then
    echo "Creating directory: $READINGS_DIR"
    mkdir -p "$READINGS_DIR"
fi

# 3. Process the CSV data
echo "Processing reading plan data..."

# Use tail to skip the header line.
# The while loop reads the line, then uses cut/sed/IFS to safely parse the quoted CSV fields.
tail -n +2 "$CSV_DATA_FILE" | while IFS= read -r line; do
    # Skip potential empty or comment lines
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # 1. Isolate the Day number (first field)
    day=$(echo "$line" | cut -d',' -f1)

    # 2. Isolate the rest of the line (the three reading fields, including quotes)
    readings_line=$(echo "$line" | cut -d',' -f2-)

    # 3. Replace the CSV delimiters (the literal '","' sequence) with a safe pipe delimiter ('|').
    safe_readings=$(echo "$readings_line" | sed 's/","/|/g')

    # 4. Now split the safe line by pipe and read into variables
    IFS='|' read -r ot nt pp <<< "$safe_readings"

    # 5. Cleanup: Strip leading/trailing double quotes from all reading fields
    ot=$(echo "$ot" | sed 's/^"//; s/"$//')
    nt=$(echo "$nt" | sed 's/^"//; s/"$//')
    pp=$(echo "$pp" | sed 's/^"//; s/"$//')

    # Check if the Day field is a number
    if [[ "$day" =~ ^[0-9]+$ ]]; then
        generate_reading_file "$day" "$ot" "$nt" "$pp"
    fi
done

echo "Script complete. All reading files have been generated in the '$READINGS_DIR' directory."

exit 0
