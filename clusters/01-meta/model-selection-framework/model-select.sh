#!/bin/bash
# model-select.sh — Interactive LLM model selection tool
# Uses verifiability and blast radius to recommend Haiku, Sonnet, or Opus
# Usage: bash model-select.sh

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Scoring
verifiability_score=0
blast_radius_score=0

echo -e "${BLUE}=== LLM Model Selection Framework ===${NC}"
echo ""
echo "This tool helps you choose the right model tier (Haiku, Sonnet, Opus)"
echo "based on task characteristics, not just capability."
echo ""
read -rp "Brief task description: " task_desc
read -rp "Specification detail (exact/ambiguous): " spec_detail
echo ""
echo "Task: $task_desc"
echo "Spec clarity: $spec_detail"
echo ""

# Section 1: Verifiability
echo -e "${BLUE}Section 1: Verifiability - Can a machine prove it's done right?${NC}"
echo ""

# Test suite
read -rp "Does this task have an automated test suite? (y/n): " has_tests
if [[ "$has_tests" =~ ^[Yy]$ ]]; then
  ((verifiability_score += 2))
  echo -e "${GREEN}✓ Tests can catch obvious errors${NC}"
else
  echo -e "${YELLOW}~ No automatic gate; model must be judged by inspection${NC}"
fi

# Type checker
read -rp "Type checker or compiler? (y/n): " has_types
if [[ "$has_types" =~ ^[Yy]$ ]]; then
  ((verifiability_score += 2))
  echo -e "${GREEN}✓ Type system enforces correctness${NC}"
else
  echo -e "${YELLOW}~ No type enforcement${NC}"
fi

# Linter
read -rp "Linter or code style enforcement? (y/n): " has_lint
if [[ "$has_lint" =~ ^[Yy]$ ]]; then
  ((verifiability_score += 1))
  echo -e "${GREEN}✓ Linter catches style/common errors${NC}"
else
  echo -e "${YELLOW}~ No automated style check${NC}"
fi

echo ""
if [ $verifiability_score -ge 4 ]; then
  echo -e "${GREEN}VERIFIABILITY: HIGH${NC} (score: $verifiability_score/5)"
  VERIFY_LEVEL="HIGH"
else
  echo -e "${YELLOW}VERIFIABILITY: LOW${NC} (score: $verifiability_score/5)"
  VERIFY_LEVEL="LOW"
fi
echo ""

# Section 2: Risk of "wrong but green"
echo -e "${BLUE}Section 2: Can it be 'wrong but green'?${NC}"
echo "(Passes the gate but is subtly incorrect)"
echo ""

read -rp "Risk of subtle correctness issues (e.g., algorithm, logic)? (y/n): " subtle_risk
if [[ "$subtle_risk" =~ ^[Yy]$ ]]; then
  echo -e "${RED}⚠ Model must act as safety net; weak model risky${NC}"
  ((verifiability_score -= 1))
else
  echo -e "${GREEN}✓ Correctness is straightforward${NC}"
fi

read -rp "Risk of test quality issues (weakened assertions, missed cases)? (y/n): " test_quality_risk
if [[ "$test_quality_risk" =~ ^[Yy]$ ]]; then
  echo -e "${RED}⚠ Tests could pass despite bugs; model strength matters${NC}"
  ((verifiability_score -= 1))
else
  echo -e "${GREEN}✓ Test quality is stable${NC}"
fi

read -rp "Risk of documentation accuracy issues? (y/n): " doc_risk
if [[ "$doc_risk" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}~ Docs can't be gate-checked; inspect needed${NC}"
fi

echo ""

# Section 3: Blast radius
echo -e "${BLUE}Section 3: Blast Radius - How expensive is a mistake?${NC}"
echo ""

read -rp "Additive change (new code, no deletions)? (y/n): " additive
if [[ "$additive" =~ ^[Yy]$ ]]; then
  ((blast_radius_score += 0))
  echo -e "${GREEN}✓ Easy to review and revert${NC}"
else
  echo -e "${YELLOW}~ Changes existing code${NC}"
fi

read -rp "Single file or tightly scoped? (y/n): " tight_scope
if [[ "$tight_scope" =~ ^[Yy]$ ]]; then
  ((blast_radius_score += 0))
  echo -e "${GREEN}✓ Limited ripple effect${NC}"
else
  echo -e "${RED}✗ Changes many files; ripple effect${NC}"
  ((blast_radius_score += 2))
fi

read -rp "Breaking change or public interface change? (y/n): " breaking_change
if [[ "$breaking_change" =~ ^[Yy]$ ]]; then
  echo -e "${RED}✗ Large blast radius; dependencies break${NC}"
  ((blast_radius_score += 3))
else
  echo -e "${GREEN}✓ Backward compatible${NC}"
fi

read -rp "Deletes or moves significant code? (y/n): " deletes_code
if [[ "$deletes_code" =~ ^[Yy]$ ]]; then
  echo -e "${RED}✗ Destructive change; hard to fix${NC}"
  ((blast_radius_score += 2))
else
  echo -e "${GREEN}✓ Code preserved${NC}"
fi

echo ""
if [ $blast_radius_score -le 1 ]; then
  echo -e "${GREEN}BLAST RADIUS: SMALL${NC} (score: $blast_radius_score)"
  RADIUS_LEVEL="SMALL"
elif [ $blast_radius_score -le 3 ]; then
  echo -e "${YELLOW}BLAST RADIUS: MEDIUM${NC} (score: $blast_radius_score)"
  RADIUS_LEVEL="MEDIUM"
else
  echo -e "${RED}BLAST RADIUS: LARGE${NC} (score: $blast_radius_score)"
  RADIUS_LEVEL="LARGE"
fi
echo ""

# Recommendation
echo -e "${BLUE}=== RECOMMENDATION ===${NC}"
echo ""
echo "Matrix position: $VERIFY_LEVEL verifiability + $RADIUS_LEVEL blast radius"
echo ""

if [[ "$VERIFY_LEVEL" == "HIGH" && "$RADIUS_LEVEL" == "SMALL" ]]; then
  echo -e "${GREEN}→ HAIKU is appropriate${NC}"
  echo "Cost: ~$0.10-0.20"
  echo "Risk: Low (gate-protected)"
  echo "False-saving tax: ~10 min cleanup acceptable"
  echo ""
  echo "When to escalate: if task fails gate twice, escalate to Sonnet"

elif [[ "$VERIFY_LEVEL" == "HIGH" && "$RADIUS_LEVEL" == "MEDIUM" ]]; then
  echo -e "${YELLOW}→ SONNET recommended (Haiku with escalation possible)${NC}"
  echo "Cost: ~$0.30-0.50"
  echo "Risk: Medium (gate helps, but broad changes risky)"
  echo "Approach: Try Sonnet, or run Haiku + escalate if review catches issues"

elif [[ "$VERIFY_LEVEL" == "HIGH" && "$RADIUS_LEVEL" == "LARGE" ]]; then
  echo -e "${YELLOW}→ SONNET (verifiability helps, but breaking changes need care)${NC}"
  echo "Cost: ~$0.30-0.50"
  echo "Risk: Medium-High (gate helps, but breaking changes risky)"
  echo "Approach: Sonnet is safer than Haiku; Opus if subtle correctness matters"

elif [[ "$VERIFY_LEVEL" == "LOW" && "$RADIUS_LEVEL" == "SMALL" ]]; then
  echo -e "${GREEN}→ SONNET is good balance${NC}"
  echo "Cost: ~$0.30-0.50"
  echo "Risk: Medium (low risk, low verifiability, but easy to fix)"
  echo "Approach: Try Sonnet first, escalate to Opus if review finds major issues"

elif [[ "$VERIFY_LEVEL" == "LOW" && "$RADIUS_LEVEL" == "MEDIUM" ]]; then
  echo -e "${YELLOW}→ SONNET recommended, Opus if "wrong but green" risk is high${NC}"
  echo "Cost: $0.30-0.50 (Sonnet) or $0.75+ (Opus)"
  echo "Risk: Medium-High (no gate + significant changes)"
  echo "Approach: Sonnet if test quality is low risk; Opus if subtle correctness matters"

else
  echo -e "${RED}→ OPUS is required (or strong escalation)${NC}"
  echo "Cost: ~$0.75-2.00+"
  echo "Risk: High (no gate, large blast radius, model is only safety net)"
  echo "Rationale: Breaking change + low verifiability = strongest model needed"
  echo ""
  echo "Why: weak model could ship with 'wrong but green' bugs (silent failures"
  echo "that pass tests but break in production). No gate catches it."
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review the framework in SKILL.md for more context"
echo "2. See README.md for detailed examples"
echo "3. If task fails gate, escalate up one tier (Haiku → Sonnet → Opus)"
echo ""
