import { render, screen } from "@testing-library/react"
import { ViolationsListItem } from "./ViolationsListItem"
import { AnalyzeReportViolation } from "@azimutt/models"

const violations: AnalyzeReportViolation[] = [
  {
    message:
      "Index mfa_factors_user_id_idx on auth.mfa_factors(user_id) can be deleted, it's covered by: factor_id_created_at_idx(user_id, created_at).",
    entity: { schema: "auth", entity: "mfa_factors" },
    attribute: ["user_id"],
    extra: {
      index: {
        name: "mfa_factors_user_id_idx",
        attrs: [["user_id"]],
        definition: "btree (user_id)",
      },
      coveredBy: [
        {
          name: "factor_id_created_at_idx",
          attrs: [["user_id"], ["created_at"]],
          definition: "btree (user_id, created_at)",
        },
      ],
    },
  },
  {
    message:
      "Index refresh_tokens_instance_id_idx on auth.refresh_tokens(instance_id) can be deleted, it's covered by: refresh_tokens_instance_id_user_id_idx(instance_id, user_id).",
    entity: { schema: "auth", entity: "refresh_tokens" },
    attribute: ["instance_id"],
    extra: {
      index: {
        name: "refresh_tokens_instance_id_idx",
        attrs: [["instance_id"]],
        definition: "btree (instance_id)",
      },
      coveredBy: [
        {
          name: "refresh_tokens_instance_id_user_id_idx",
          attrs: [["instance_id"], ["user_id"]],
          definition: "btree (instance_id, user_id)",
        },
      ],
    },
  },
  {
    message:
      "Index sessions_user_id_idx on auth.sessions(user_id) can be deleted, it's covered by: user_id_created_at_idx(user_id, created_at).",
    entity: { schema: "auth", entity: "sessions" },
    attribute: ["user_id"],
    extra: {
      index: {
        name: "sessions_user_id_idx",
        attrs: [["user_id"]],
        definition: "btree (user_id)",
      },
      coveredBy: [
        {
          name: "user_id_created_at_idx",
          attrs: [["user_id"], ["created_at"]],
          definition: "btree (user_id, created_at)",
        },
      ],
    },
  },
]

describe("ViolationsListItem", () => {
  test("Should render the rule name", () => {
    render(
      <ViolationsListItem
        name={"duplicated index"}
        level="high"
        violations={[]}
      />
    )
    expect(screen.getByText("duplicated index")).toBeDefined()
  })

  test("Should render the rule level", () => {
    render(
      <ViolationsListItem
        name={"duplicated index"}
        level="high"
        violations={[]}
      />
    )
    expect(screen.getByText("high")).toBeDefined()
  })

  test("Should render the violations", () => {
    render(
      <ViolationsListItem
        name={"duplicated index"}
        level="high"
        violations={violations}
      />
    )
    expect(screen.getByText(violations[0].message)).toBeDefined()
    expect(screen.getByText(violations[1].message)).toBeDefined()
    expect(screen.getByText(violations[2].message)).toBeDefined()
  })

  test("Should tells how many more violations", () => {
    render(
      <ViolationsListItem
        name={"duplicated index"}
        level="high"
        violations={violations}
        totalViolations={5}
      />
    )
    expect(
      screen.getByText(`${5 - violations.length} more violations`)
    ).toBeDefined()
  })
})
