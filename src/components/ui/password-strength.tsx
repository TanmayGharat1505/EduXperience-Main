import { useMemo } from "react";
import { Progress } from "@/components/ui/progress";
import { CheckCircle, X } from "lucide-react";

interface PasswordStrengthProps {
  password: string;
}

export function PasswordStrength({ password }: PasswordStrengthProps) {
  const strength = useMemo(() => {
    const checks = {
      length: password.length >= 8,
      uppercase: /[A-Z]/.test(password),
      lowercase: /[a-z]/.test(password),
      number: /\d/.test(password),
      special: /[!@#$%^&*(),.?":{}|<>]/.test(password),
    };

    const score = Object.values(checks).filter(Boolean).length;
    
    return {
      score,
      checks,
      level: score < 2 ? 'weak' : score < 4 ? 'medium' : 'strong',
      percentage: (score / 5) * 100
    };
  }, [password]);

  const getColor = () => {
    switch (strength.level) {
      case 'weak': return 'bg-destructive';
      case 'medium': return 'bg-warning';
      case 'strong': return 'bg-success';
      default: return 'bg-muted';
    }
  };

  if (!password) return null;

  return (
    <div className="space-y-3">
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-sm font-medium">Password Strength</span>
          <span className={`text-sm font-medium ${
            strength.level === 'weak' ? 'text-destructive' :
            strength.level === 'medium' ? 'text-warning' :
            'text-success'
          }`}>
            {strength.level === 'weak' ? 'Weak' :
             strength.level === 'medium' ? 'Medium' : 'Strong'}
          </span>
        </div>
        <Progress value={strength.percentage} className="h-2" />
      </div>
      
      <div className="space-y-1">
        {[
          { key: 'length', label: 'At least 8 characters' },
          { key: 'uppercase', label: 'One uppercase letter' },
          { key: 'lowercase', label: 'One lowercase letter' },
          { key: 'number', label: 'One number' },
          { key: 'special', label: 'One special character' },
        ].map(({ key, label }) => (
          <div key={key} className="flex items-center gap-2 text-sm">
            {strength.checks[key as keyof typeof strength.checks] ? (
              <CheckCircle className="h-4 w-4 text-success" />
            ) : (
              <X className="h-4 w-4 text-muted-foreground" />
            )}
            <span className={strength.checks[key as keyof typeof strength.checks] ? 'text-success' : 'text-muted-foreground'}>
              {label}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}